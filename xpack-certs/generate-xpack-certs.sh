#!/bin/bash
set -e

BLUE='\033[1;34m'
RESET='\033[0m'

function print_header() {
  BLACK='\033[1;30m'
  PINK='\033[1;35m'
  RESET='\033[0m'
  On_IBlue='\033[0;104m' 
  On_Black='\033[40m' 
  BWhite='\033[1;37m'  

  echo -e "\n${On_Black}${BWhite}╔═════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${On_Black}${BWhite}║                                ${BWhite}X - PACK                                     ${BWhite}║${RESET}"
  echo -e "${On_Black}${BWhite}╠═════════════════════════════════════════════════════════════════════════════╣${RESET}"
  echo -e "${On_Black}${BWhite}║                    ${BWhite}Elasticsearch Certificate Generator                      ║${RESET}"
  echo -e "${On_Black}${BWhite}╚═════════════════════════════════════════════════════════════════════════════╝${RESET} \n"
}

function pause_exit() {
  echo -e "\033[1;31m❌ $1\033[0m"
  exit 1
}
function confirm_yes_no() {
  local prompt="$1"  
  echo -e "${BLUE}${prompt} [Y/n]: ${RESET}"
  while true; do
    read -p "" yn
    yn="${yn:-Y}"
    case "$yn" in
      [Yy]*) return 0 ;;  # Yes
      [Nn]*) return 1 ;;  # No
      *) echo "Please answer Y or N." ;;  # Invalid input handling
    esac
  done
}

print_header

# Elasticsearch version
read -p $'\033[1;34mEnter Elasticsearch version to use for cert generation (e.g., 9.0.0): \033[0m' ES_VERSION
echo -e "✅ \033[4;30mYou selected: \033[0;90m\033[3m$ES_VERSION\033[0m"

# Detect container runtime
AVAILABLE_RUNTIMES=()
command -v docker &> /dev/null && AVAILABLE_RUNTIMES+=("docker")
command -v podman &> /dev/null && AVAILABLE_RUNTIMES+=("podman")

if [[ ${#AVAILABLE_RUNTIMES[@]} -eq 0 ]]; then
  pause_exit "Neither Docker nor Podman found on this system."
fi

echo "Available container runtimes:"
for i in "${!AVAILABLE_RUNTIMES[@]}"; do
  echo "$((i+1))) ${AVAILABLE_RUNTIMES[$i]}"
done

while true; do
  read -p $'\033[1;34m\nSelect the number corresponding to your choice:\033[0m ' choice
  if [[ "$choice" =~ ^[1-9]$ && $((choice-1)) -lt ${#AVAILABLE_RUNTIMES[@]} ]]; then
    RUNTIME="${AVAILABLE_RUNTIMES[$((choice-1))]}"
    echo -e "✅ \033[4;30mYou selected:\033[0;90m\033[3m$RUNTIME\033[0m"
    break
  else
    echo -e "\033[1;31m❌ Invalid choice.\033[0m"
  fi
done

# Check if daemon is running
if ! $RUNTIME info &>/dev/null; then
  pause_exit "$RUNTIME daemon is not running. Please start it and try again."
fi

# Support both .yml and .yaml
if [[ -f "$(pwd)/instances.yml" ]]; then
  INSTANCES_FILE="$(pwd)/instances.yml"
elif [[ -f "$(pwd)/instances.yaml" ]]; then
  INSTANCES_FILE="$(pwd)/instances.yaml"
else
  INSTANCES_FILE=""
fi

ITALIC_GRAY='\033[3;90m'
RESET='\033[0m'
BLUE='\033[1;34m'

# If file exists, proceed
if [[ -n "$INSTANCES_FILE" ]]; then
  echo -e "\n ${ITALIC_GRAY}⚠️  Existing instances file found at: $INSTANCES_FILE${RESET}"
  echo "-----------------------------------"
  cat "$INSTANCES_FILE"
  echo "-----------------------------------"
  if confirm_yes_no "Do you want to use this configuration?"; then
    SKIP_NODE_INPUT=true
  else
    echo "🔁 Regenerating fresh configuration..."
    rm -f "$INSTANCES_FILE"
    INSTANCES_FILE="$(pwd)/instances.yml"  # Default to .yml for new
  fi
else
  INSTANCES_FILE="$(pwd)/instances.yml"  # Default path for new
fi

# If not skipping, prepare new config
if [[ -z "$SKIP_NODE_INPUT" ]]; then
  echo -e "\033[1;34mHow many nodes in the cluster?\033[0m"
  select CLUSTER_SIZE_OPTION in "1" "3" "Custom"; do
    case $CLUSTER_SIZE_OPTION in
      1|3) CLUSTER_SIZE=$CLUSTER_SIZE_OPTION; break ;;
      Custom)
        read -p $'\033[1;34mEnter custom cluster size: \033[0m' CLUSTER_SIZE
        [[ "$CLUSTER_SIZE" =~ ^[0-9]+$ ]] && break
        echo -e "\033[1;31mInvalid number\033[0m"
        ;;
      *) echo -e "\033[1;31mChoose 1, 2 or 3\033[0m" ;;
    esac
  done
  echo -e "✅ You selected cluster size: \033[1;32m$CLUSTER_SIZE\033[0m"

  echo "instances:" > "$INSTANCES_FILE"
  for ((i=1; i<=CLUSTER_SIZE; i++)); do
    echo ""
    read -p $'\033[1;34mEnter container name for node '"$i"$' (e.g., es0'"$i"$'): \033[0m' CONTAINER_NAME
    read -p $'\033[1;34mEnter IP address for '"$CONTAINER_NAME"$': \033[0m' NODE_IP
    read -p $'\033[1;34mDo you have FQDN for '"$CONTAINER_NAME"$'? [Y/n]: \033[0m' FQDN_ANSWER
    FQDN_ANSWER="${FQDN_ANSWER:-Y}"

    if [[ $FQDN_ANSWER =~ ^[Yy]$ ]]; then
      read -p $'\033[1;34mEnter FQDN for '"$CONTAINER_NAME"$': \033[0m' NODE_FQDN
    else
      NODE_FQDN=""
    fi

    echo "  - name: $CONTAINER_NAME" >> "$INSTANCES_FILE"
    echo "    ip:" >> "$INSTANCES_FILE"
    [[ -n "$NODE_IP" ]] && echo "      - $NODE_IP" >> "$INSTANCES_FILE"
    echo "      - 127.0.0.1" >> "$INSTANCES_FILE"
    echo "    dns:" >> "$INSTANCES_FILE"
    echo "      - $CONTAINER_NAME" >> "$INSTANCES_FILE"
    echo "      - localhost" >> "$INSTANCES_FILE"
    [[ -n "$NODE_FQDN" ]] && echo "      - $NODE_FQDN" >> "$INSTANCES_FILE"
  done
fi
echo -e "\033[1;91m🧹 Cleaning up old node certs...\033[0m"
rm -rf config/certs/*

# Prepare certs dir
mkdir -p ./config/certs

# Generate certs
echo -e "\n\033[1;34mGenerating CA and certificates...\033[0m"
$RUNTIME run --rm \
  -v "$(pwd)/config/certs:/usr/share/elasticsearch/config/certs" \
  -v "$INSTANCES_FILE:/usr/share/elasticsearch/instances.yml" \
  docker.elastic.co/elasticsearch/elasticsearch:$ES_VERSION \
  bash -c "\
    cd /usr/share/elasticsearch && \
    if [ ! -f config/certs/ca.zip ]; then
      echo 'Generating CA...'
      bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip
      unzip -q config/certs/ca.zip -d config/certs
    fi && \
    if [ -f instances.yml ]; then
      find config/certs -type f \( -name '*.crt' -o -name '*.key' \) ! -name 'ca.crt' ! -name 'ca.key' -delete

      echo 'Generating node certs...'
      bin/elasticsearch-certutil cert --silent --pem \
        --in instances.yml \
        --out config/certs/certs.zip \
        --ca-cert config/certs/ca/ca.crt \
        --ca-key config/certs/ca/ca.key
      unzip -q config/certs/certs.zip -d config/certs
    else
      echo '❌ instances.yml not found at instances.yml'
      exit 1
    fi" || pause_exit "Failed to generate certificates."

# Permissions
echo -e "\n\033[1;34mSetting file permissions...\033[0m"
chown -R root:root ./config/certs 2>/dev/null || echo "Skipping chown (non-Linux host)"
find ./config/certs -type d -exec chmod 750 {} \;
find ./config/certs -type f -exec chmod 640 {} \;

# Done
echo -e "\n\033[4;30m✅ Certificates generated at: ./config/certs\033[0m"
echo -e "\n\033[1;35m============ \033[1;35mGENERATED FILES ============\033[0m"

if command -v tree &> /dev/null; then
  echo -e "\n📂 Certificate files:"
  tree ./config/certs
else
  echo -e "\n📂 Certificate files:"
  find ./config/certs
fi