# get-salesforce-data-dictionary
A simple shell script to dump the data dictionary from Salesforce as a set of JSON files.

# Background

Salesforce provide API's to ingest data and also discover the data dictionary for available tables. This repo is specifically looking at discovering the data dictionary. This data dictionary maybe useful to type and transform data which is ingested.

If you wish to ingest data, use the [Meltano](https://meltano.com/), at [Salesforce Tap](https://hub.meltano.com/extractors/tap-salesforce).

## Salesforce API's

For data extracts, Salesforce provide three methods to obtain data via an API.

- A RESTful API - which is designed for small amounts of data
- Bulk API v 1.0 - which was the initial Salesforce API offering
- Bulk API v 2.0 - a later offering which requires less code and is designed for larger extracts.

## Salesforce Authentication

There are a couple of methods to Authenticate with Salesforce when using the Salesforce API’s. Options include

- Salesforce Account
- Salesforce OAuth credentials

The OAuth tokens are a preferred approach, this guide describes how to establish them.

The steps to establish an OAuth2 Refresh token is somewhat complicated, I have followed the steps from this recommended guide https://medium.com/@bpmmendis94/obtain-access-refresh-tokens-from-salesforce-rest-api-a324fe4ccd9b .

# Connecting to Salesforce

This section describes the process of creating an OAuth Token and Salesforce Connecting App.

## Stage 1: Generate an Authorisation to get the Client Secret

In this stage we will gathering the following information.

1. The URL for the API call i.e. the Salesforce Instance
2. The Client ID which is also known as the Consumer Key
3. The redirect URI

It is important to note that the URL for the API varies from instance to instance. The following steps will need to be repeated for each Salesforce environment.

Please follow these steps to get the right information the next stage. 

1. Login into the appropriate Salesforce environment e.g. https://appname.my.salesforce.com/ environment. Note: You will need an account with enough admin privileges to access certain areas of Salesforce.

2. Click on the Cog in the upper right corner and click on Setup.

3. Then in the Left-Hand pane, go to Apps, then App Manager.

4. We are going to create a new Connected App. Click on “New Connected App” just under your profile avatar.

5. Enter the following details for your Connected Application. Note we are assuming Meltano is going to ingest the data here.

    ```shell
    Name                    - Meltano
    API Name                - Meltano
    Contact Email           - <Your Email Address or Support Email Address>
    Enable OAuth Settings   - Tick this box
    Callback URL            - http://localhost
    Select OAuth Scopes     - Adding the following scopes:

                            - Manage user data via APIs (api)
                            - Manage user data via Web Browsers (web)
                            - Perform request at anytime (refresh_token, offline_access)
    Require Secret for Web Server Flow
                            - Tick this box
    ```
6. Navigate using the Left-Hand navigation panel to **Manage Connected Apps**. Set the following permissions on the newly created **Meltano** Connected App.

7. Navigate back to the **App Manager** in the Left Hand Navigation panel. Once you are in the App Manage, locate the **Meltano App** and at the Right-Hand side of the list click the down arrow and view for the Meltano record.

8. In the API (Enabled OAuth Settings) section you need to copy the following details. Place them in a Notepad to construct the URL to gain an Authorisation Token
    - The **Consumer Key**
    - The **Consumer Secret**
    - The **Callback URL**

9. Construct the URL placing in the known Salesforce URL, Consumer Key, and Callback URL. Note: The Consumer Secret will be used in stage 2.

    https://<YOUR_SALESFORCE_INSTANCE_URL>/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<CALLBACK_URL>

10. Place that particular code into another tab in the browser that you are current logged into Salesforce with - Note: You must be logged into Salesforce for this to work.

11. Hit enter to go to that site. You will initially think nothing has happened, but look carefully at the URL. It should have changed and you will see a **code=** in the URL. Copy the string that follows after the code= as this will be the new **code** used for the next stage which is creating an Authorisation Token.


## Stage 2: Obtain the Salesforce OAuth Credentials

The following script can be run in a Linux Server which has the curl command. You will need to substitute in the values which you have obtained from Stage 1.

Please Update the <PROVIDE_STRING> sections for the following items.

1. **USERID** : Your Proxy Server User ID
2. **PASSWORD** : Your Proxy Server Password
3. **CODE** : The string returned after code= in the URL produced by executing the constructed URL in Stage 1.
4. **CONSUMER_KEY** : The Consumer Key from the OAuth App discovered in Stage 1
5. **CLIENT_SECRET** :  The Client Key from the OAuth App discovered in Stage 1
6. **CALLBACK_URL**: The Callback URL from the OAuth App discovered in Stage 1


```shell
#!/bin/bash
# Comment out the proxy server lines if you don't use a proxy server
export http_proxy=http://<USERID>:<PASSWORD>@<PROXY_SERVER>:3128
export https_proxy=http://<USERID>:<PASSWORD>@<PROXY_SERVER>:3128
curl --location --request POST "https://<YOUR_SALESFORCE_INSTANCE_URL>/services/oauth2/token?code=<code>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CLIENT_SECRET>&redirect_uri=http://<CALLBACK_URL>" --data-urlencode \
--header "Content-Type: application/x-www-form-urlencoded" \
--header "Cookie: BrowserId=i5-SoQCkEeyUt1ng5MwoZw; CookieConsentPolicy=0:0"
```

## Stage 3 : Gather the Refresh Token details

If the you are successful in run Stage 2. You will receive a JSON message back which will include a series of Key : Value pairs.

Record the **refresh_token** value. This is used to set the refresh_token environmental variable.

At the completion of this stage you have gathered all the required keys to make an authenticated call to the Salesforce API using OAuth2 credentials.

## Stage 4 : Set the appropriate Environmental Variables

To call the Salesforce API using a Refresh OAuth2 Token set the following environmental variables when using Meltano. The values will be supplied from Steps 3 and 4.

For Meltano, this is the environment variables.

```shell
TAP_SALESFORCE_CLIENT_ID=<CONSUMER_KEY>
TAP_SALESFORCE_CLIENT_SECRET=<CLIENT_SECRET>
TAP_SALESFORCE_REFRESH_TOKEN=<REFRESH_TOKEN>
```

For the **get_salesforce_data_dictionary.sh** utility add these parameters to the .env file.

# Running the get_salesforce_data_dictionary.sh utility

You should have the .env file updated with the correct credentials to connect to Salesforce. 

To extract the data dictionary for the list of tables in interest, run the following command.

```shell
./get_salesforce_data_dictionary.sh
```