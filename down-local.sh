#!/usr/bin/env bash
# Arrête les microservices (les données Postgres sont conservées)
set -euo pipefail
cd "$(dirname "$0")"

SERVICES=(users fidelity statistiques commande catalogue front gateway)
if [ $# -gt 0 ]; then SERVICES=("$@"); fi

for s in "${SERVICES[@]}"; do
  echo "==> $s"
  docker compose -f "$s/docker-compose.yml" -f "$s/compose.local.yaml" down
done
