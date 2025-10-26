#!/bin/bash
set -e

# --- Configuration ---
# Path to your domains config file
DOMAINS_FILE="domains.json"
# --- End Configuration ---

# --- Helper Functions ---
function check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: $1 is not installed. Please install it to continue."
    exit 1
  fi
}

# --- Main Script ---

# 1. Check for dependencies
check_command "docker"
check_command "docker-compose"
check_command "jq"
check_command "openssl"

# 2. Check for config file
if [ ! -f "$DOMAINS_FILE" ]; then
    echo "Error: Domain configuration file '$DOMAINS_FILE' not found."
    exit 1
fi

# 3. Create necessary directories
echo ">>> Creating data directories..."
mkdir -p data/nginx/conf.d
mkdir -p data/ssl

# 4. Generate Nginx configs and Self-Signed Certs
echo ">>> Generating Nginx configurations and SSL certificates..."
# Clear old configs
rm -f data/nginx/conf.d/*.conf

# Use jq to parse the JSON file and loop through each entry
jq -c '.[]' "$DOMAINS_FILE" | while read -r item; do
    domain=$(jq -r '.domain' <<< "$item")
    target=$(jq -r '.target' <<< "$item")
    config_file="data/nginx/conf.d/${domain}.conf"
    ssl_dir="data/ssl/${domain}"
    key_file="${ssl_dir}/privkey.pem"
    cert_file="${ssl_dir}/fullchain.pem"

    echo "  -> Processing $domain..."

    # Create self-signed certificate if it doesn't exist
    if [ ! -f "$cert_file" ]; then
        echo "    -> Generating self-signed certificate for $domain..."
        mkdir -p "$ssl_dir"
        openssl req -x509 -nodes -newkey rsa:4096 \
            -keyout "$key_file" \
            -out "$cert_file" \
            -days 3650 \
            -subj "/CN=${domain}"
    else
        echo "    -> Certificate for $domain already exists."
    fi

    # Create the Nginx configuration file for the domain
    cat > "$config_file" << EOL
server {
    listen 80;
    server_name ${domain};

    
}

server {
    listen 443 ssl http2;
    server_name ${domain};

    # SSL Configuration
    ssl_certificate /etc/ssl/certs/${domain}/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/${domain}/privkey.pem;

    # Proxy Configuration
    location / {
        proxy_pass ${target};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOL
done

# 5. Start all services
echo ">>> Starting Nginx service..."
docker-compose up -d --force-recreate --build

echo ">>> Setup complete!"
echo "!!! IMPORTANT: You must now edit your hosts file. See README.md for instructions."

