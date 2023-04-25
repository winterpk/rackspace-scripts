# Rackspace Load Balancer Auto Certificate #

## Description 

This script is used to automate the installation of certificates on a Rackspace load balancer

## Installation

- Update the variables at the top of the script 
    - API_KEY
    - USERNAME
    - LB_ID
    - LB_REGION
    - CERT
    - INTERMEDIATE
    - PK
- Upload to your rackspace server `/root/scripts/`
- Run the script `/root/scripts/rackspace-lb-auto-cert.sh`

## Notes

The main purpose of this script was to automate the installation of [https://certbot.eff.org/](certobot) / letsencrypt certificates on a Rackspace load balancer. The idea is to run this script based on the output of `certbot renew`. If the renew command did renew a script then this will install it on the load balancer.
