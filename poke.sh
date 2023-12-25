#!/bin/bash

# ==============================================================
# ||                   DNS Tool                               ||
# ||               Wilder Army Knife                          ||
# ||            Written by Captain Wilder                     ||
# ==============================================================
#
# Check and install 'whois' if not present
install_whois() {
  if which whois >/dev/null; then
    # whois is already installed, no action required
    true 
  else
    echo "Installing whois..."
    if [[ ! -z $(which yum) ]]; then
      sudo yum install whois -y
    elif [[ ! -z $(which apt) ]]; then
      sudo apt-get install whois -y
    else
      echo "Error: Package manager not found. Cannot install 'whois'."
      exit 1
    fi
  fi
}
install_whois

# Ensure a domain is provided
if [ -z "$1" ]; then
  echo "Usage: poke.sh <domain>"
  exit 1
fi
DOMAIN="$1"

# Perform DNS Lookups
# Retrieve A record
ip=$(dig +short A "$DOMAIN")
ip_org=$(echo "$ip" | head -n1 )

# Lookup organization details from whois
org=$(whois "$ip_org" | grep 'OrgName:' | awk '{$1=""; print substr($0,2)}')

# Retrieve MX record
mx=$(dig +short MX "$DOMAIN")

# Retrieve NS records
ns=$(dig +short NS "$DOMAIN")

# Retrieve CNAME record
cname=$(dig +short CNAME "www.$DOMAIN")

# Retrieve TXT record for SPF
txt=$(dig +short TXT "$DOMAIN" | grep spf)

# Retrieve domain registrar from whois
registrar=$(whois "$DOMAIN" | grep -m 1 'Registrar:' | awk '{$1=""; print substr($0,2)}')

# Check for HTTPS availability
if ! curl --output /dev/null --silent --head --fail --connect-timeout 5 "https://$DOMAIN"; then
  echo "No HTTPS available, or the domain is not reachable."
  ssl_expiry="no SSL"
  ssl_issuer="no SSL"
else
  # Fetch SSL details
  ssl_output=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates -issuer)
  ssl_expiry=$(echo "$ssl_output" | grep 'notAfter' | awk -F= '{print $2}')
  ssl_issuer=$(echo "$ssl_output" | grep 'issuer=' | sed -n 's/.*O = \(.*\), CN = .*/\1/p')
fi

# Output formatting and display
RED="\033[31m"
RESET="\033[0m"

# Function to print details in color
print_with_color() {
    local label=$1
    local value=$2
    echo -e "${RED}${label}:${RESET}\n${value}"
}

# Display DNS & SSL collected data
echo "----------------------- DNS & SSL Details -----------------------"
print_with_color "WebHost" "$org"
print_with_color "Registrar" "$registrar"
print_with_color "SSL Expiration" "$ssl_expiry"
print_with_color "SSL Issuer" "$ssl_issuer"
print_with_color "IP" "$ip"
print_with_color "NS records" "$ns"
print_with_color "CNAME record" "$cname"
print_with_color "MX record" "$mx"
print_with_color "SPF" "$txt"
echo "-----------------------------------------------------------------"
echo "Loading port check..."
echo "-------------------------- Port Check ---------------------------"
#Port Checks
# Check SSH
declare -A services=(
    [FTP]=21
    [SSH]=22
    [Telnet]=23
    [SMTP]=25
    [DNS]=53
    [HTTP]=80
    [HTTPS]=443
    [IMAP]=143
    [RDP]=3389
    [SMB]=445
    [SNMP]=161
    [MSSQL]=1433
    [MYSQL]=3306
)

for service in "${!services[@]}"; do
    (
        result=$(nc -z -v -w 1 "$DOMAIN" "${services[$service]}" 2>&1)
        if echo "$result" | grep -q "succeeded"; then
            echo "$service is open"
        fi
    ) &
done

wait
echo "-----------------------------------------------------------------"
