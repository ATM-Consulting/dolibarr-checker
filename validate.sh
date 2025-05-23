#!/bin/bash

# Crée un répertoire pour les outils dans le dossier personnel
# Ajoute ce répertoire au PATH du système
TOOLS_DIR="$HOME/.dolibarr-checker/bin"
mkdir -p "$TOOLS_DIR"
export PATH="$TOOLS_DIR:$PATH"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
RESET='\033[0m'

# 📦 Chemin du dépôt courant (module)
# Vérifie si on est dans un module Dolibarr
MODULE_PATH=$(git rev-parse --show-toplevel)
if [[ "$MODULE_PATH" != *"/custom/"* ]]; then
    echo -e "${YELLOW}⚠️  Hors d'un module Dolibarr (custom/). Aucun test exécuté.${RESET}"
    exit 0
fi

# Vérifie l'existence du fichier main.inc.php et stocke le chemin d'accès
HTDOCS_PATH=""
CURRENT="$MODULE_PATH"
while [ "$CURRENT" != "/" ]; do
    if [ -d "$CURRENT/custom" ] && [ -f "$CURRENT/main.inc.php" ]; then
        HTDOCS_PATH="$CURRENT"
        break
    fi
    CURRENT=$(dirname "$CURRENT")
done

if [ -z "$HTDOCS_PATH" ]; then
    echo -e "${RED}❌ Impossible de localiser le fichier main.inc.php à partir du module.${RESET}"
    exit 1
fi

MAIN_INC="$HTDOCS_PATH/main.inc.php"
echo -e "${GREEN}✔️  main.inc.php détecté : $MAIN_INC${RESET}"



# Copie du fichier de configuration pre-commit
CONFIG_SOURCE="${HTDOCS_PATH/htdocs/dev}"
CONFIG_DEST="$MODULE_PATH/dev/"

PRECOMMIT_SOURCE="$HTDOCS_PATH/../.pre-commit-config.yaml"
PRECOMMIT_DEST="$MODULE_PATH/.pre-commit-config.yaml"

echo -e "${BLUE}▶ Copie de la configuration pre-commit...${RESET}"
if [ -d "$CONFIG_SOURCE" ]; then
    cp -r "$CONFIG_SOURCE" "$CONFIG_DEST"
    cp -r "$PRECOMMIT_SOURCE" "$PRECOMMIT_DEST"
    echo -e "${GREEN}✅ Configuration pre-commit copiée avec succès.${RESET}"
else
    echo -e "${RED}❌ Le repertoire de configuration pre-commit non trouvé : $CONFIG_SOURCE${RESET}"
    exit 1
fi


# ▶ Exécution de pre-commit
echo -e "${BLUE}▶ Vérifications pre-commit...${RESET}"

if ! command -v pre-commit &> /dev/null; then
    echo -e "${RED}❌ pre-commit n'est pas installé. Installe-le avec 'pip install pre-commit'.${RESET}"
    EXIT_CODE=1
else
    echo -e "${GREEN}✅ PHPUnit $PHPUNIT_VERSION déjà présent.${RESET}"
fi

# ▶ Exécution de pre-commit
echo -e "${BLUE}▶ Vérifications pre-commit...${RESET}"

if ! command -v pre-commit &> /dev/null; then
    echo -e "${RED}❌ pre-commit n'est pas installé. Installe-le avec 'pip install pre-commit'.${RESET}"
    EXIT_CODE=1
else
    pre-commit gc  # Nettoyage des hooks obsolètes

    # Sauvegarde du répertoire courant
    CURRENT_DIR=$(pwd)

    # Exécution + capture propre du code retour
    LOG_FILE="/tmp/pre-commit.log"
    pre-commit run --config ".pre-commit-config.yaml" | tee "$LOG_FILE"
    PRECOMMIT_EXIT=${PIPESTATUS[0]}

    # Retour au répertoire initial
    cd "$CURRENT_DIR"

    if [ "$PRECOMMIT_EXIT" -ne 0 ]; then
        echo -e "${RED}❌ Des erreurs ont été détectées par pre-commit.${RESET}"
        echo -e "${YELLOW}📄 Contenu de $LOG_FILE :${RESET}"
        cat "$LOG_FILE"
        EXIT_CODE=1
    else
        echo -e "${GREEN}✅ Tous les hooks pre-commit sont passés.${RESET}"
    fi
fi

# À la fin du script, avant de sortir :
echo -e "${BLUE}▶ Nettoyage des fichiers temporaires...${RESET}"
if [ -d "$CONFIG_DEST" ]; then
    rm -r "$CONFIG_DEST"
    rm -r "$PRECOMMIT_DEST"
    echo -e "${GREEN}✅ Fichier de configuration temporaire supprimé.${RESET}"
else
    echo -e "${YELLOW}ℹ️ Aucun fichier temporaire à nettoyer.${RESET}"
fi


EXIT_CODE=0


# 🧾 Résumé
echo -e "${BLUE}---------------------------------------${RESET}"
if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les contrôles sont passés avec succès.${RESET}"
else
    echo -e "${RED}❌ Des erreurs ont été détectées. Corrigez-les avant de committer.${RESET}"
fi
echo -e "${BLUE}---------------------------------------${RESET}"

exit $EXIT_CODE

