#!/usr/bin/env bash
# Lance les microservices sur le SERVEUR (VM OpenStack) avec les images GHCR.
# Seuls les services qui ont un compose.server.yaml exposent un port (aujourd'hui : la gateway, port 8080).
# Les API, le front et les bases restent accessibles uniquement par le réseau Docker.
#
#   ./up-server.sh                 -> tous les services
#   ./up-server.sh users commande  -> seulement ceux-là
#
# Prérequis : un fichier <service>/.env par service et docker login ghcr.io
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

  files=(-f "$s/docker-compose.yml")
  if [ -f "$s/compose.server.yaml" ]; then
    files+=(-f "$s/compose.server.yaml")
  fi

  echo "==> $s"
  docker compose "${files[@]}" pull
  docker compose "${files[@]}" up -d
done
