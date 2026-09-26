# Ingress is Dokploy's Traefik, not Eureka or a Java gateway

Public HTTP enters through Dokploy-managed Traefik. Domains and path prefixes are declared once in the Dokploy UI (or compose labels); Dokploy writes Traefik routes. Services call each other by Compose/Dokploy DNS names and env URLs, not a discovery registry. Eureka and Spring Cloud Gateway go away with the rest of the Java app stack.
