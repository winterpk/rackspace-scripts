#!/bin/bash

## Update this with API key from Rackspace
API_KEY=''

## Username from Rackspace account with API access
USERNAME=''

## Load Balancer ID
LB_ID=''

## LB REGION
LB_REGION=''

## Path to certificate to be installed on the load balancer
CERT=''

## Path the intermediate certificate to be installed on the load balancer
INTERMEDIATE=''

## Path to the private key to be install on the load balancer
PK=''

AUTH=$(curl -s https://identity.api.rackspacecloud.com/v2.0/tokens  \
	-X POST \
	-d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"$USERNAME\",\"apiKey\":\"$API_KEY\"}}}" \
	-H "Content-type: application/json")

TOKEN=$(echo "$AUTH" | grep -oP "(?<=APIKEY\"\],\"id\":\").*(?=\",\"tenant\")")

TENANT_ID=$(echo "$AUTH" | grep -oP "(?<=compute\:default\"\,\"tenantId\"\:\").*?(?=\"\,\"description\")")

ENDPOINT="https://$LB_REGION.loadbalancers.api.rackspacecloud.com/v1.0/"$(echo "$AUTH" | python3 -m json.tool | grep -oP "(?<=$LB_REGION.loadbalancers.api.rackspacecloud.com/v1.0/).*?(?=\")")

CERT=$(cat "$CERT")
CERT=$(echo "${CERT//$'\n'/\\n}")'\n'
INTERMEDIATE=$(cat "$INTERMEDIATE")
INTERMEDIATE=$(echo "${INTERMEDIATE//$'\n'/\\n}")'\n'
PK=$(cat "$PK")
PK=$(echo "${PK//$'\n'/\\n}")'\n'

## Update the cert
curl "$ENDPOINT/loadbalancers/$LB_ID/ssltermination" \
        -H "X-Auth-Token: $TOKEN"  \
        -H "X-Project-Id: $TENANT_ID" \
	-H "Content-type: application/json" \
	-X PUT \
  -s
	-d "{\"sslTermination\":{\"certificate\":\"$CERT\",\"enabled\":true,\"secureTrafficOnly\":true,\"privatekey\":\"$PK\",\"intermediateCertificate\":\"$INTERMEDIATE\",\"securePort\":443}}" \ > /dev/null
