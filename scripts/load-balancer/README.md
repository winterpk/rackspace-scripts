# Rackspace Load Balancer Scripts #

## Installation

- Update the variables at the top of the scripts

- Upload to your rackspace server (eg. `/etc/letsencrypt/renewal-hooks/deploy/rackspace-lb-auto-cert.sh`)
- Make executable `sudo chmod u+x /etc/letsencrypt/renewal-hooks/deploy/rackspace-lb-auto-cert.sh`

## Notes

The main purpose of this script was to automate the installation of [https://certbot.eff.org/](certobot) / letsencrypt certificates on a Rackspace load balancer. Place this script in the `/etc/letsencrypt/renewal-hooks/deploy/` hook folder with executable permissions and it will install the cert automatically on the Rackspace load balancer.
