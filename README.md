# nb-glean-networking-lab

A private lab for testing Glean's Web and WordPress connectors against a self-hosted website on AWS EC2.

## What's here

`KingdomOfTravel` — a mock Canadian travel rewards website (modelled on princeoftravel.com), built as a static HTML site with a navy/gold design.

## Files

| Path | Purpose |
|---|---|
| `index.html` | Homepage |
| `credit-cards.html` | Credit card rankings |
| `destinations.html` | Destination redemption guides |
| `about.html` | About page |
| `guides/points-101.html` | Beginner's travel rewards guide |
| `articles/best-credit-cards-2025.html` | Featured article |
| `assets/style.css` | Stylesheet |
| `sitemap.xml` | Sitemap (20 URLs) |
| `robots.txt` | Open crawl + sitemap pointer |
| `docker-compose.yml` | WordPress + MySQL stack for WordPress connector testing |

## Hosting on EC2

### Option A — Static site (Web connector)

```bash
# On EC2
npx serve . -p 80
```

Point Glean Web connector at `http://<EC2-private-ip>/` with sitemap `http://<EC2-private-ip>/sitemap.xml`.

### Option B — WordPress (WordPress connector)

```bash
# On EC2 (requires Docker + Docker Compose)
docker compose up -d
```

WordPress will be available at `http://<EC2-private-ip>/` after ~30s. Complete the 5-minute install, then configure the [Glean WordPress connector](https://docs.glean.com/connectors/native/wordpress/) with Application Password credentials.

## Networking

For Glean SaaS to reach a private EC2:
- **Quick path**: assign a public IP, allowlist Glean's crawler IPs in the security group
- **Lab path**: deploy Glean on-prem crawler inside the VPC, or set up a VPN tunnel from Glean's network to your VPC

VPN tunnel setup is a planned next step for this lab.
