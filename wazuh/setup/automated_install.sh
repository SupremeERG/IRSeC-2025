#!/usr/bin/bash

# Installs Wazuh server (all modules) on a single
# system according to https://documentation.wazuh.com/current/installation-guide/index.html's
# assisted installation documentation

WAZUH_SERVER_IP_ADDRESS= # enter server IP address here
WAZUH_DASHBOARD_CUSTOM_PORT=443 # change if 443 is used for another service

# Wazuh indexer installation
echo "[+] Installing Wazuh Indexer"
bash wazuh-install.sh --generate-config-files
bash wazuh-install.sh --wazuh-indexer node-1
bash wazuh-install.sh --start-cluster
tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O | grep -P "\'admin\'" -A 1
echo
echo "[+] Use the password above to test if the cluster is working properly for the next 2 prompts"
echo
sleep 3
curl -k -u admin https://$WAZUH_SERVER_IP_ADDRESS:9200
curl -k -u admin https://$WAZUH_SERVER_IP_ADDRESS:9200/_cat/nodes?v


# Wazuh server cluster installation
echo
echo "[+] Installing Wazuh server cluster"
echo
bash wazuh-install.sh --wazuh-server wazuh-1



# Wazuh dashboard installation
echo
echo "[+] Installing Wazuh dashboard"
echo
bash wazuh-install.sh --wazuh-dashboard dashboard --port $WAZUH_DASHBOARD_CUSTOM_PORT
echo
echo "[+] All Wazuh passwords are stored in wazuh-install-files.tar in the wazuh-passwords.txt file"
echo

# Installation complete
echo "[+] Installation complete (if no errors occured)