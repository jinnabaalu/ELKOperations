#!/bin/bash
set -e

read -s -p "\ 🔐 Enter Elasticsearch (elastic) password: " ELASTIC_PASSWORD
echo
read -s -p "\ 🔐 Enter Kibana System (kibana_system) password: " KIBANA_PASSWORD
echo

echo "\n ⏳ Waiting for Elasticsearch to be ready..."
until curl -s --cacert ./certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" https://localhost:9200 -o /dev/null; do
  sleep 5
done

echo -e "\n \033[1;32m✅ Elasticsearch is up!\033[0m"

echo "\n 🔧 Setting kibana_system password..."
until curl -s -X POST --cacert ./certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H "Content-Type: application/json" https://localhost:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do    echo "\n ⏳ Retrying to set kibana_system password..."
    sleep 5
done

echo -e "\n \033[1;35m✅ kibana_system password set successfully!\033[0m"
