#!/usr/bin/env bash
# init.sh — Run once on the EC2 instance after cloning the repo.
# Reads the private IP from EC2 instance metadata, generates sitemap.xml
# and robots.txt from templates, then deploys everything to Nginx's web root.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_ROOT="/usr/share/nginx/html"

# ── 1. Get private IP from EC2 instance metadata (IMDSv2) ────────────────────
# IMDSv2 requires a session token first — plain curl returns 401 on most
# modern EC2 instances where IMDSv2 is enforced.
echo "Fetching private IP from EC2 instance metadata..."

IMDS_TOKEN=$(curl -s --connect-timeout 3 \
  -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

if [[ -z "$IMDS_TOKEN" ]]; then
  echo "ERROR: Could not obtain IMDSv2 token. Are you on an EC2 instance?"
  exit 1
fi

PRIVATE_IP=$(curl -s --connect-timeout 3 \
  -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

# Validate — a real IP is short and contains only digits and dots
if [[ -z "$PRIVATE_IP" || ! "$PRIVATE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Metadata returned an unexpected value: $PRIVATE_IP"
  echo "Are you running this on an EC2 instance?"
  exit 1
fi

echo "Private IP: $PRIVATE_IP"

# ── 2. Generate sitemap.xml and robots.txt from templates ─────────────────────
echo "Generating sitemap.xml..."
sed "s|{{PRIVATE_IP}}|$PRIVATE_IP|g" "$REPO_DIR/sitemap-template.xml" > "$REPO_DIR/sitemap.xml"

echo "Generating robots.txt..."
sed "s|{{PRIVATE_IP}}|$PRIVATE_IP|g" "$REPO_DIR/robots-template.txt" > "$REPO_DIR/robots.txt"

# ── 3. Copy site to Nginx web root ────────────────────────────────────────────
echo "Copying site files to $WEB_ROOT..."
sudo cp -r "$REPO_DIR"/. "$WEB_ROOT/"

# ── 4. Remove template files from web root (not meant to be served) ───────────
sudo rm -f "$WEB_ROOT/sitemap-template.xml"
sudo rm -f "$WEB_ROOT/robots-template.txt"
sudo rm -f "$WEB_ROOT/docker-compose.yml"
sudo rm -rf "$WEB_ROOT/scripts"

# ── 5. Reload Nginx ───────────────────────────────────────────────────────────
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "Done. Site deployed to http://$PRIVATE_IP/"
echo "Sitemap: http://$PRIVATE_IP/sitemap.xml"
echo "Robots:  http://$PRIVATE_IP/robots.txt"
echo ""
echo "Glean Web connector seed URL:  http://$PRIVATE_IP/"
echo "Glean Web connector sitemap:   http://$PRIVATE_IP/sitemap.xml"
