#!/bin/bash

[ ! -f .env ] || export $(grep -v '^#' .env | xargs)

if [ $IS_SANDBOX = "true" ]
then
    SALESFORCE_INSTANCE_PREFIX=test
else
    SALESFORCE_INSTANCE_PREFIX=login
fi

# Obtain a new refresh token
refresh_token=$(curl --location --request POST "https://$SALESFORCE_INSTANCE_PREFIX.salesforce.com/services/oauth2/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=$CLIENT_ID" \
--data-urlencode "client_secret=$CLIENT_SECRET" \
--data-urlencode "refresh_token=$REFRESH_TOKEN")

bearer_token=$(echo $refresh_token | jq -r '.access_token')
instance_url=$(echo $refresh_token | jq -r '.instance_url')

# Make directory for output - data_dictonary
mkdir -p data_dictionary

# Get data dictiony for each table defined in the __SELECT environment variable
for object in ${__SELECT//,/ }
do

    curl --location --request GET "$instance_url/services/data/$SALESFORCE_API_VERSION/sobjects/$object/describe/" --header "Authorization: Bearer $bearer_token" | jq '.' > data_dictionary/$object.json
done
