#!/bin/bash
set -x
set -e

# Generate a private key
openssl genrsa -out selfsigned.key 2048

# Generate a CSR (Certificate Signing Request)
openssl req -new -key selfsigned.key -out selfsigned.csr

# Generate a Self-Signed Certificate and answer the questions for certificate signing request
openssl x509 -req -days 365 -in selfsigned.csr -signkey selfsigned.key -out selfsigned.crt

# Import the self-signed certificate into AWS Certificate Manager
# Write ARN to 'certificate.json'
aws acm import-certificate --certificate fileb://selfsigned.crt --private-key fileb://selfsigned.key --region eu-north-1 | tee certificate.json
