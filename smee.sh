#!/bin/bash
echo -n "Please enter your Jenkins Token: "
read -s TOKEN
read -p "Now add the SMEE URL here (refer to https://smee.io/): " URL
echo -n "Don't forget to add SMEE URL as a webhook in GitHub repo!"
echo
read -p "What is your Jenkins URL?  " JENKINS_URL
read -p "Also specify the port (Usually 8080): " PORT

MY_SECRET=$(echo -n "$USER:$TOKEN" | base64)

npx smee \
	-u $URL \
	-t "$JENKINS_URL/generic-webhook-trigger/invoke?token=$TOKEN" \
	-p $PORT
