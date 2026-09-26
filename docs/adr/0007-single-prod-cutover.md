# Java is frozen; Go is a greenfield port, then cutover, then new work

No further feature work on Java. Production Java stays as-is. Go is written to match that running system, proven against a dump, then one Traefik/Dokploy cutover. Certificates and other new features land on Go after that port, not as extra scope inside the first cutover.
