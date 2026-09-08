# pihost

Héberge tes projets Docker Compose sur un Raspberry Pi, un sous-domaine par projet,
HTTPS automatique via [Caddy](https://caddyserver.com).

```
pihost add https://github.com/toi/cubix cubix     # => https://cubix.mondomaine.fr
```

## Comment ça marche

- Caddy tourne dans Docker, branché sur un réseau `pihost_web`, et écoute sur 80/443.
- Chaque projet est cloné dans `/srv/pihost/apps/<nom>/repo` et lancé avec son propre
  `compose.yaml` **plus** un override généré par pihost qui :
  - attache le service web au réseau `pihost_web` sous l'alias `<nom>.pihost` ;
  - retire les `ports:` publiés sur l'hôte (plus aucun conflit de port entre projets).
- Un fichier `/srv/pihost/caddy/sites/<nom>.caddy` fait le `reverse_proxy` vers
  `<nom>.pihost:<port conteneur>`. Caddy obtient le certificat Let's Encrypt tout seul.

Le service et le port sont détectés depuis `ports:` ou `expose:` du compose du projet.
S'il y a un doute, précise `--service` et `--port`.

## Installation sur le Pi

```
git clone <url de ce dépôt> && cd pihost
sudo ./install.sh mondomaine.fr moi@mail.fr
# puis se déconnecter / reconnecter pour le groupe docker
```

`install.sh` installe Docker, git, jq, copie `pihost` dans `/usr/local/bin` et lance
`pihost init`.

## Côté domaine et box

1. Chez le registrar, un enregistrement DNS **A** `*` (wildcard) vers l'IP publique de la box.
   Ajoute aussi `@` ou `www` si tu veux la racine.
2. Sur la Freebox (Paramètres > Gestion des ports), rediriger **TCP 80** et **TCP+UDP 443**
   vers l'IP locale du Pi. Donne une IP fixe au Pi via le bail DHCP statique.
3. Si ton IP publique n'est pas fixe, active le DynDNS de la Freebox ou un client `ddclient`.

Sans DNS public et redirection de ports, Let's Encrypt ne pourra pas délivrer de certificat.

## Commandes

```
pihost init <domaine> [email]                  Initialise et démarre Caddy
pihost add <url-git> <sous-domaine> [options]  Clone, démarre, publie
      --service <nom>   service à exposer (auto si un seul expose un port)
      --port <port>     port conteneur (auto depuis ports:/expose:)
      --branch <b>      branche git
      --name <n>        nom interne (défaut : sous-domaine)
      --keep-ports      conserve les ports publiés sur l'hôte
pihost update <nom>                            git pull + rebuild + redémarrage (rien n'est supprimé)
pihost update                                  Met à jour pihost lui-même (sans toucher aux conteneurs)
pihost remove <nom> [--volumes]                Arrête et supprime (+ données avec --volumes)
pihost list                                    Liste les applications
pihost logs|restart|stop|start <nom>
pihost env <nom>                               Édite le .env puis redémarre
pihost caddy logs|reload|up|down
```

Le sous-domaine peut être court (`cubix` => `cubix.<domaine>`) ou un nom complet
(`app.autredomaine.fr`), utile pour un second domaine pointant vers le Pi.

## Prérequis côté projet

- Un `compose.yaml` (ou `docker-compose.yml`) à la racine, avec un service web qui
  déclare `ports:` ou `expose:`.
- Les images doivent exister en **arm64** (ou être construites via `build:`).
- Un `.env.example` est copié en `.env` au premier déploiement si aucun `.env` n'existe.

## Arborescence

```
/srv/pihost/
├── config                 DOMAIN / EMAIL
├── caddy/                 compose.yaml, Caddyfile, sites/*.caddy
└── apps/<nom>/
    ├── app.env            métadonnées (url, hôte, service, port)
    ├── override.yaml      override compose généré
    └── repo/              clone git du projet
```

Variables : `PIHOST_ROOT` (défaut `/srv/pihost`), `PIHOST_HTTP_PORT` / `PIHOST_HTTPS_PORT`
(ports hôte de Caddy, défaut 80/443).
