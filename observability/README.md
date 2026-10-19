# observability

POC Prometheus + Grafana. Prometheus récupère les métriques de catalogue toutes les 15 s (`/actuator/prometheus`) et les garde 15 jours.

Pour les logs, catalogue écrit en JSON (variable `LOGGING_STRUCTURED_FORMAT_CONSOLE` dans son docker-compose). Alloy lit les logs des conteneurs du réseau network-mss et les envoie à Loki, qui les garde 15 jours.

Pour les traces, catalogue utilise OpenTelemetry et envoie ses traces à Tempo (variables MANAGEMENT_OPENTELEMETRY_* et MANAGEMENT_TRACING_* dans son docker-compose). Tempo les garde 15 jours.

## Lancer

```bash
cp observability/.env.example observability/.env
./up-local.sh catalogue observability
```

- Prometheus : http://localhost:9090 (Status > Targets pour voir si catalogue est UP)
- Grafana : http://localhost:3001 (admin / mot de passe du .env)

Dans Grafana, la source Prometheus est déjà configurée. On peut regarder les métriques dans Explore, ou importer le dashboard 4701 (JVM Micrometer) via Dashboards > New > Import.

Pour les logs : Explore > Loki, par exemple `{container="glop-catalogue-catalogue-api-1"} | json | level="ERROR"`.

Pour les traces : Explore > Tempo > Search, on voit chaque requête HTTP avec son temps.
