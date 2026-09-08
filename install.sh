#!/usr/bin/env bash
# Installation de pihost sur Raspberry Pi OS (Debian). À lancer avec sudo depuis le dépôt cloné :
#   sudo ./install.sh [domaine] [email]
set -euo pipefail
[[ $(id -u) -eq 0 ]] || { echo "Lance avec sudo"; exit 1; }
USER_NAME="${SUDO_USER:-$USER}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=/srv/pihost

echo "▶ Paquets de base"
apt-get update -qq
apt-get install -y -qq git jq curl ca-certificates >/dev/null

if ! command -v docker >/dev/null; then
  echo "▶ Installation de Docker (get.docker.com)"
  curl -fsSL https://get.docker.com | sh
fi
usermod -aG docker "$USER_NAME"

echo "▶ Installation de la commande pihost"
install -m 0755 "$HERE/pihost" /usr/local/bin/pihost
mkdir -p "$ROOT"
chown -R "$USER_NAME:$USER_NAME" "$ROOT"

echo "✔ pihost installé."
if [[ -n "${1:-}" ]]; then
  echo "▶ Initialisation pour $1"
  sudo -u "$USER_NAME" -g docker pihost init "$1" "${2:-}"
else
  echo "  Étape suivante : pihost init <domaine> [email]"
fi
echo "  Déconnecte-toi et reconnecte-toi (groupe docker) avant d'utiliser pihost sans sudo."
