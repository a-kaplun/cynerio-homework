#!/usr/bin/env bash

set -x

# Add an api `/healthcheck` which will always return {"status":"ok"}

# Test `/healthcheck` call -- should return 
output=$(curl \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    http://localhost:5000/healthcheck)
if [[ $output != '200' ]]; then
    echo "ERROR: healthcheck request failed with response code $output"
    exit 1
fi

output=$(curl \
    --fail \
    --silent \
    http://localhost:5000/healthcheck)
if [[ $output != '{"status":"ok"}' ]]; then
    echo "ERROR: healthcheck request got unexpected output: $output"
    exit 1
fi

# test `/get/something` with a non-existing value - should return 404 
output=$(curl \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    http://localhost:5000/get/something)
if [[ $output != '404' ]]; then
    echo "ERROR: /get/something request did not return 404. Got instead $output"
    exit 1
fi

# test `/set` with data '{"id": "one", "data": "one"}'. Should return 2xx.
output=$(curl \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    --request POST \
    --header "Content-Type: application/json" \
    --data '{"id": "one", "data": "one"}' \
    http://localhost:5000/set)
if [[ ! $output =~ 2[0-9]+ ]]; then
    echo "ERROR: /set request did not return 2xx. Got instead $output"
    exit 1
fi

# test `/get/one` with an existing value - should return 200 and the value 
output=$(curl \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    http://localhost:5000/get/one)
if [[ $output != '200' ]]; then
    echo "ERROR: /get/one request did not return 200. Got instead $output"
    exit 1
fi

output=$(curl \
    --fail \
    --silent \
    http://localhost:5000/get/one)
if [[ $output != '{"one":"one"}' ]]; then
    echo "ERROR: /get/one request got unexpected output: $output"
    exit 1
fi


echo "COMPLETED SUCCESSFULLY"
