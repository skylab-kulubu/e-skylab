# Public traffic uses Dokploy (optional Cloudflare Tunnel); internal traffic uses Docker DNS

Browsers and webhooks reach the VPS through Dokploy Traefik. A Cloudflare Tunnel may sit in front of Traefik so the host does not expose 80/443; that is still ingress only. Service-to-service calls use the Dokploy/Compose network name and env URLs. They do not go through Traefik, Eureka, or Cloudflare.

If a service is scaled to N replicas, Docker/Dokploy DNS round-robins that name for internal callers, and Traefik load-balances the same containers for public routes. APIs stay stateless (JWT). One-shot jobs (cron) run on a single replica. Postgres and Redis stay one instance each. Eureka is not required for this.
