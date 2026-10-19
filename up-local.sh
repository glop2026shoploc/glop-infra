#!/usr/bin/env bash
# Lance les microservices en local avec les images GHCR.
#   ./up-local.sh                 -> tous
#   ./up-local.sh users commande  -> seulement ceux-là
set -euo pipefail
cd "$(dirname "$0")"

SERVICES=(users fidelity statistiques commande catalogue front gateway)
if [ $# -gt 0 ]; then SERVICES=("$@"); fi

docker network inspect network-mss >/dev/null 2>&1 || docker network create network-mss

for s in "${SERVICES[@]}"; do
  if [ ! -f "$s/.env" ]; then
    echo "Fichier $s/.env manquant : cp $s/.env.example $s/.env" >&2
    exit 1
  fi
  echo "==> $s"
  docker compose -f "$s/docker-compose.yml" -f "$s/compose.local.yaml" pull
  docker compose -f "$s/docker-compose.yml" -f "$s/compose.local.yaml" up -d
done
