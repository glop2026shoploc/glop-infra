# glop-infra

Lance **toute l'application glop** (microservices + bases de données + front) sur ta machine avec Docker, à partir des images publiées par la CI.

> Ce repo ne contient **aucun code applicatif** : seulement la configuration pour faire tourner les images.

---

## Sommaire

- [Comment ça marche](#comment-ça-marche)
- [Prérequis](#prérequis)
- [Installation (une seule fois)](#installation-une-seule-fois)
- [Lancer l'application](#lancer-lapplication)
- [Arrêter l'application](#arrêter-lapplication)
- [Ports et accès](#ports-et-accès)
- [Mettre à jour les services](#mettre-à-jour-les-services)
- [Tester son code avec les autres services](#tester-son-code-avec-les-autres-services)
- [Commandes utiles](#commandes-utiles)
- [Structure du repo](#structure-du-repo)

---

## Comment ça marche


- Chaque microservice a **son dossier**, avec **sa propre base PostgreSQL** et un **réseau privé** API ↔ BDD.
- Les API (et le front) sont reliées par le réseau partagé **`network-mss`** et s'appellent par leur nom : `http://<service>-api:8080`.
- Les images viennent de **GHCR** (`ghcr.io/glop2026shoploc/<service>`) : rien n'est compilé ici.

---

## Prérequis

| Outil | Vérifier |
|---|---|
| Docker (Docker Desktop sous Windows/macOS), **lancé** | `docker --version` |
| Docker Compose v2 | `docker compose version` |
| Git | `git --version` |
| Un terminal **bash** (Linux, macOS, Git Bash ou WSL sous Windows) | — |

Organisation conseillée des repos (tous clonés **côte à côte**) :

```
projets/
├── glop-infra/
├── users/
├── fidelity/
├── statistiques/
├── commande/
├── catalogue/
└── front/
```

---

## Installation (une seule fois)

### 1. Cloner le repo

```bash
git clone https://github.com/glop2026shoploc/glop-infra.git
cd glop-infra
```

### 2. Créer les fichiers de secrets

- Copier le fichier .env.example pour creer un fichier .env avec les vrais secrets

**Ce que ça fait :** crée un fichier `.env` par service à partir du modèle. Il contient le tag de l'image et les identifiants de la base. Modifie les mots de passe si tu veux (en local ce n'est pas critique). Les `.env` ne sont **jamais commités** (`.gitignore`).

### 3. Se connecter au registry GHCR

```bash
docker login ghcr.io
```

- **Username** : ton pseudo GitHub
- **Password** : un token GitHub (pas ton mot de passe)
  → <https://github.com/settings/tokens> → *Generate new token (classic)* → cocher **uniquement `read:packages`**

**Ce que ça fait :** autorise Docker à télécharger les images privées de l'organisation. À faire une fois par machine (`Login Succeeded`).


## Lancer l'application

```bash
./up-local.sh
```

**Ce que ça fait, dans l'ordre :**

1. crée le réseau partagé `network-mss` s'il n'existe pas ;
2. vérifie que chaque `.env` existe ;
3. `docker compose pull` : télécharge la dernière image de chaque service depuis GHCR ;
4. `docker compose up -d` : pour chaque service, crée le réseau privé et le volume, démarre PostgreSQL, **attend qu'il soit prêt** (healthcheck), puis démarre l'API ;
5. au démarrage de chaque API, Spring Boot se connecte à sa base et applique les migrations.

Tout tourne **en arrière-plan** (`-d`) : la commande rend la main.

**Lancer seulement certains services :**

```bash
./up-local.sh users catalogue
```

**Vérifier que tout tourne :**

```bash
docker ps
```

Chaque service doit afficher deux conteneurs : `glop-<service>-<service>-api-1` et `glop-<service>-<service>-db-1` (**healthy**).

---

## Arrêter l'application

| Commande | Effet |
|---|---|
| `./down-local.sh` | arrête et supprime les conteneurs de tous les services — **les données sont conservées** |
| `./down-local.sh users` | idem pour un seul service |
| `docker compose -f users/docker-compose.yml down -v` | ⚠️ supprime aussi le volume : **efface la base de `users`** |

Les conteneurs ont `restart: unless-stopped` : s'ils tournent quand tu éteins ton PC, ils redémarrent au prochain lancement de Docker.

---

## Ports et accès

| Service | API | PostgreSQL (glop-infra) | PostgreSQL (dev, compose du repo) |
|---|---|---|---|
| users | http://localhost:8081 | `localhost:5441` | `localhost:5432` |
| fidelity | http://localhost:8082 | `localhost:5442` | `localhost:5433` |
| statistiques | http://localhost:8083 | `localhost:5443` | `localhost:5434` |
| commande | http://localhost:8084 | `localhost:5444` | `localhost:5435` |
| catalogue | http://localhost:8085 | `localhost:5445` | `localhost:5436` |
| front | http://localhost:3000 | — | — |

- Ces ports ne sont ouverts **qu'en local** (fichiers `compose.local.yaml`, liés à `127.0.0.1`). En prod, rien n'est exposé directement.
- Base de données (DBeaver, IntelliJ…) : utilisateur et mot de passe = ceux du `.env` du service.
- Entre conteneurs, les API s'appellent par leur nom : `http://users-api:8080`, `http://catalogue-api:8080`…

---

## Mettre à jour les services

Quand un collègue merge sur `main`, la CI publie une nouvelle image. Pour la récupérer :

```bash
./up-local.sh            # pull + redémarre uniquement ce qui a changé
./up-local.sh catalogue  # ou un seul service
```

**Utiliser une version précise** : dans `<service>/.env`, remplace `TAG=latest` par un tag visible sur <https://github.com/orgs/glop2026shoploc/packages> (ex. `TAG=sha-a1b2c3d` ou `TAG=1.2.0`), puis relance.

---

## Tester son code avec les autres services

Les images de glop-infra contiennent le code de **`main`**, pas tes modifications locales.

### Cas le plus courant : ton service appelle les autres

```bash
# 1. les autres services, version main
./up-local.sh users fidelity statistiques commande

# 2. ton service, depuis son repo
cd ../catalogue
#Optionnel de faire docker compose up -d car Spring Boot démarre automatiquement la base avec la dépendance compose
docker compose up -d          # sa base de dev
# puis Run dans IntelliJ      # ton code, sur le même port (ex. 8085)
```

Ton service appelle les autres via `localhost:8081`, `8084`…

> Ne lance pas le même service **à la fois** dans glop-infra et dans l'IDE (même port).

Un service ne doit tourner qu’une seule fois : soit depuis glop-infra, soit depuis IntelliJ. Pour coder sur un service lancé par glop-infra, arrête-le d’abord (./down-local.sh <service>), puis lance-le depuis IntelliJ.

### Si d'autres services doivent appeler ton code

Les conteneurs ne voient pas une application lancée dans l'IDE. Construis une image de ton code et lance-la ici :

```bash
cd ../catalogue
./mvnw clean package -DskipTests
docker build -t ghcr.io/glop2026shoploc/catalogue:local .

cd ../glop-infra
TAG=local docker compose -f catalogue/docker-compose.yml -f catalogue/compose.local.yaml up -d
```

Pour revenir à la version de `main` : `./up-local.sh catalogue`.

---

## Commandes utiles

| Commande | Ce que ça fait |
|---|---|
| `docker ps` | liste les conteneurs en cours |
| `docker network ls` | liste les réseaux (`network-mss`, `glop-users_users-net`…) |
| `docker volume ls` | liste les volumes de données |

---

## Structure du repo

```
glop-infra/
├── up-local.sh                 # lance des services (tous par défaut)
├── down-local.sh               # arrête des services
├── .gitignore                  # exclut les .env
├── users/
│   ├── docker-compose.yml      # API + PostgreSQL + réseaux + volume (local ET prod)
│   ├── compose.local.yaml      # ports ouverts en local uniquement
│   ├── .env.example            # modèle de configuration (commité)
│   └── .env                    # ta configuration (NON commité)
├── fidelity/ statistiques/ commande/ catalogue/   # même structure
└── front/
```

### Que contient un `docker-compose.yml` de service ?

| Élément | Rôle |
|---|---|
| `<service>-api` | l'application, image `ghcr.io/glop2026shoploc/<service>:${TAG}` |
| `<service>-db` | PostgreSQL 17, données dans un volume |
| `environment` | URL / utilisateur / mot de passe de la base transmis à Spring Boot (`SPRING_DATASOURCE_*`) et `SERVER_PORT=8080` |
| `healthcheck` + `depends_on` | l'API attend que la base soit prête |
| `<service>-net` | réseau privé API ↔ BDD |
| `network-mss` | réseau partagé entre les API (`external`, créé par `up-local.sh`) |
| `restart: unless-stopped` | redémarrage automatique |

### Ajouter un nouveau microservice

1. Copier un dossier existant (ex. `users/`) et remplacer le nom partout.
2. Choisir de nouveaux ports dans `compose.local.yaml`.
3. L'ajouter à la liste `SERVICES` de `up-local.sh` et `down-local.sh`.

---
