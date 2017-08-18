#!/bin/bash

count=1
while [[ 3 -gt $count ]]; do
    docker build --rm -t rancherlabs/terraform_ha:latest -f Dockerfile .
    if [[ $? -eq 0 ]]; then break; fi
    count=$(($count + 1))
    echo "Repeating failed Docker build ${count} of 3..."
done

env | egrep '^(TF_|AWS_).*\=.+' | sort > .env

# Add the certificates
mkdir -p certs
touch certs/{key.pem,crt.pem,chain.pem}
echo -e "${RANCHER_SSL_CERT}" > certs/crt.pem
echo -e "${RANCHER_SSL_KEY}" > certs/key.pem
echo -e "${RANCHER_SSL_CHAIN}" > certs/chain.pem
chmod 600 certs/*

echo "Success: Image Built and environments initialized"
