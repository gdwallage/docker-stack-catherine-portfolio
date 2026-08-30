# Docker Stack — Catherine Wallage Portfolio & Store (`catherine-portfolio`)

Dedicated high-performance WordPress & WooCommerce Docker Swarm stack for `catherinewallage.uk`.

## Architecture
- **Web**: Nginx Alpine (`catherine-portfolio_web`) with static asset caching.
- **PHP**: PHP 8.3-FPM (`catherine-portfolio_wordpress`) with OPcache, Imagick, WebP, AVIF, and WP-CLI.
- **Data Tier**: Central `databases_mariadb` (database: `catherinedb`, table prefix: `cewc_`).
- **Object Cache**: Shared `databases_redis` (isolated database index `1`).
- **Edge Ingress**: Caddy (`core-infra`) with Cloudflare TLS and Authentik SSO `/wp-admin` protection.
