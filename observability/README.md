# observability

POC Prometheus + Grafana. Prometheus récupère les métriques de catalogue toutes les 15 s (`/actuator/prometheus`) et les garde 15 jours.

## Lancer

```bash
cp observability/.env.example observability/.env
./up-local.sh catalogue observability
```

- Prometheus : http://localhost:9090 (Status > Targets pour voir si catalogue est UP)
- Grafana : http://localhost:3001 (admin / mot de passe du .env)

Dans Grafana, la source Prometheus est déjà configurée. On peut regarder les métriques dans Explore, ou importer le dashboard 4701 (JVM Micrometer) via Dashboards > New > Import.
