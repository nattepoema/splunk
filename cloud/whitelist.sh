#!/bin/bash

IP=$(curl -s checkip.amazonaws.com)
IP="$IP/32"
echo $IP

printf "Hello, please enter your Splunk Cloud stack-prefix
For example, https://abc.splunkcloud.com - abc is the prefix
>"
read stack

printf "Enter the feature you want to whitelist for
search-api
hec
s2s
search-ui
idm-ui
idm-api
>"
read feature


printf "Enter username (with sc_admin role) 
>"
read username

printf "Enter password
>"
read -s password

TOKEN_URL="https://admin.splunk.com/$stack/adminconfig/v2/tokens"
TOKEN_RESPONSE=$(curl -s -u $username:$password -X POST $TOKEN_URL --header 'Content-Type: application/json' --data-raw "{\"user\" : \"$username\",\"audience\" : \"acs-test\", \"expiresOn\" : \"+1d\"}")

echo $TOKEN_RESPONSE

TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.token')
echo $TOKEN

printf "Printing current subnets
"
curl https://admin.splunk.com/$stack/adminconfig/v2/access/$feature/ipallowlists --header "Authorization: Bearer $TOKEN"

whitelist_ips="[ \"$IP\" ]"


echo $whitelist_ips

printf "Adding the new IP allow lists"
curl -X POST "https://admin.splunk.com/$stack/adminconfig/v2/access/$feature/ipallowlists" --header 'Content-Type: application/json' --header "Authorization: Bearer $TOKEN" --data "{\"subnets\":  $whitelist_ips}"

printf "Printing updated subnets
"
curl https://admin.splunk.com/$stack/adminconfig/v2/access/$feature/ipallowlists --header "Authorization: Bearer $TOKEN"

# Wait for a few seconds to start deploy
printf "This is going to take a few minutes, please feel free to grab a coffee."
sleep 5
printf "Checking for status
"

status=$(curl -s "https://admin.splunk.com/$stack/adminconfig/v2/status" --header "Authorization: Bearer $TOKEN" | jq -r '.infrastructure.status')
echo "$status"
while [[ $status != "Ready" ]]; do 
 echo "Waiting for status to be ready"
 echo "$status"
 status=$(curl -s "https://admin.splunk.com/$stack/adminconfig/v2/status" --header "Authorization: Bearer $TOKEN" | jq -r '.infrastructure.status')
 sleep 10
done


