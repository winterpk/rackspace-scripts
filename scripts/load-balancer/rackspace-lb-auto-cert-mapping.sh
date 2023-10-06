#!/bin/bash

#############################################
## MODIFY THESE VARIABLES WITH LIVE VALUES ##
#############################################

## Update this with API key from Rackspace
API_KEY=''

## Username from Rackspace account with API access
USERNAME=''

## Load Balancer ID
LB_ID=''

## LB REGION
LB_REGION=''

## Array of json objects with hostname and paths to the respective certificate files
declare -a MAPPINGS

MAPPINGS=('{"hostName":"sub1.example.com", "privateKey":"/path/to/sub1.example.com/privkey.pem", "certificate":"/path/to/sub1.example.com/cert.pem", "intermediateCertificate":"/path/to/sub1.example.com/chain.pem"}' '{"hostName":"sub2.example.com", "privateKey":"/path/to/sub2.example.com/privkey.pem", "certificate":"/path/to/sub2.example.com/cert.pem", "intermediateCertificate":"/path/to/sub2.example.com/chain.pem"}')

#########################
## DO NOT MODIFY BELOW ##
#########################




# Authenticate
AUTH=$(curl -s https://identity.api.rackspacecloud.com/v2.0/tokens  \
    -X POST \
    -d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"$USERNAME\",\"apiKey\":\"$API_KEY\"}}}" \
    -H "Content-type: application/json")

TOKEN=$(echo "$AUTH" | grep -oP "(?<=APIKEY\"\],\"id\":\").*(?=\",\"tenant\")")

TENANT_ID=$(echo "$AUTH" | grep -oP "(?<=compute\:default\"\,\"tenantId\"\:\").*?(?=\"\,\"description\")")

ENDPOINT="https://$LB_REGION.loadbalancers.api.rackspacecloud.com/v1.0/"$(echo "$AUTH" | python3 -m json.tool | grep -oP "(?<=$LB_REGION.loadbalancers.api.rackspacecloud.com/v1.0/).*?(?=\")")

EXISTING_MAPPINGS=$(curl "$ENDPOINT/loadbalancers/$LB_ID/ssltermination/certificatemappings"  \
         -H "X-Auth-Token: $TOKEN"  \
         -H "X-Project-Id: $TENANT_ID" \
         -H "Content-type: application/json")

LOOPCOUNT=0
MAPINDEX=0
while [ ${#MAPPINGS[@]} -gt $MAPINDEX ]
do
    CERT_PATH=$(echo ${MAPPINGS[$MAPINDEX]} | tr ',' '\n' | awk '/"certificate"/ {print}' | sed -e 's/"certificate"://' -e 's/^[[:space:]]*//' -e 's/["]//g')

    INTERMEDIATE_PATH=$(echo ${MAPPINGS[$MAPINDEX]} | tr ',' '\n' | awk '/"intermediateCertificate"/ {print}' | sed -e 's/"intermediateCertificate"://' -e 's/^[[:space:]]*//' -e 's/["]//g' -e 's/[}]//g')

    PK_PATH=$(echo ${MAPPINGS[$MAPINDEX]} | tr ',' '\n' | awk '/"privateKey"/ {print}' | sed -e 's/"privateKey"://' -e 's/^[[:space:]]*//' -e 's/["]//g')

    CERT=$(cat "$CERT_PATH")
    CERT=$(echo "${CERT//$'\n'/'\\n'}")'\\n'

    INTERMEDIATE=$(cat "$INTERMEDIATE_PATH")
    INTERMEDIATE=$(echo "${INTERMEDIATE//$'\n'/'\\n'}")'\\n'

    PK=$(cat "$PK_PATH")
    PK=$(echo "${PK//$'\n'/'\\n'}")'\\n'

    PAYLOAD=$(echo ${MAPPINGS[$MAPINDEX]} | awk -v find="$PK_PATH" -v replace="$PK" '{sub(find,replace,$0); print $0 }' | awk -v find="$CERT_PATH" -v replace="$CERT" '{sub(find,replace,$0); print $0 }' | awk -v find="$INTERMEDIATE_PATH" -v replace="$INTERMEDIATE" '{sub(find,replace,$0); print $0 }')

    ## Check LB status
    STATUS=$(curl "$ENDPOINT/loadbalancers/$LB_ID" \
        -H "X-Auth-Token: $TOKEN"  \
        -H "X-Project-Id: $TENANT_ID" \
        -H "Content-type: application/json")

    STATUS=$(echo $STATUS | grep -Eo -m 1 '"status"[^,]*' | grep -Eo '[^:]*$' | head -1 | sed -e 's/\"//g')

    if [ $STATUS = 'ACTIVE' ]
    then

        ## Check if this mapping already exists
        HOSTNAME=$( echo ${MAPPINGS[$MAPINDEX]} | grep -Eo '"hostName"[^,]*' | grep -Eo '[^:]*$' | head -1 | sed -e 's/\"//g')

        EXISTING_MAPPING_ID=$(echo $EXISTING_MAPPINGS | grep -Eo '"id":[0-9]+,"hostName":"'$HOSTNAME | grep -Eo '"id":[0-9]+[^,]' | sed 's/"id"://' )

        if [ $EXISTING_MAPPING_ID ]
        then
                # Update existing certificate mapping
                echo 'Certificate mapping for '$HOSTNAME' already exists. UPDATING...'
                curl "$ENDPOINT/loadbalancers/$LB_ID/ssltermination/certificatemappings/"$EXISTING_MAPPING_ID \
                     -H "X-Auth-Token: $TOKEN"  \
                     -H "X-Project-Id: $TENANT_ID" \
                     -H "Content-type: application/json" \
                     -X PUT \
                     -d '{"certificateMapping":'"$PAYLOAD"'}'
        else
                # Add new certificate mapping
                echo 'Adding certificate mapping for '$HOSTNAME
                curl "$ENDPOINT/loadbalancers/$LB_ID/ssltermination/certificatemappings" \
                     -H "X-Auth-Token: $TOKEN"  \
                     -H "X-Project-Id: $TENANT_ID" \
                     -H "Content-type: application/json" \
                     -X POST \
                     -d '{"certificateMapping":'"$PAYLOAD"'}'
        fi

        MAPINDEX=$((MAPINDEX +1))
    fi

    # Avoid infinite loops, only try 12 times
    LOOPCOUNT=$((LOOPCOUNT +1))
    if [ $LOOPCOUNT -gt 10 ]
    then
        break
    fi

    sleep 1
done
