#!/bin/bash

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
MODULE_PATH=$(git rev-parse --show-toplevel)

# Vérifie si on est dans un module Dolibarr
if [[ "$MODULE_PATH" != *"/custom/"* ]]; then
    echo -e "${YELLOW}⚠️  Hors d'un module Dolibarr (custom/). Aucun test exécuté.${RESET}"
    exit 0
fi

# 🔼 Remonter jusqu'à trouver le dossier htdocs contenant main.inc.php
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

# ▶ Téléchargement de PHPUnit selon la version PHP
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
PHPUNIT_META_FILE="$TOOLS_DIR/.phpunit_version"

get_phpunit_version() {
    case "$PHP_VERSION" in
        "7.1") echo "7" ;;
        "7.4") echo "9" ;;
        "8.0") echo "9" ;;
        "8.1") echo "10" ;;
        "8.2") echo "11" ;;
        "8.3") echo "12" ;;
        *) echo "" ;;
    esac
}

PHPUNIT_VERSION=$(get_phpunit_version)
PHPUNIT_BIN="$TOOLS_DIR/phpunit-$PHPUNIT_VERSION"
PHPUNIT_URL="https://phar.phpunit.de/phpunit-$PHPUNIT_VERSION.phar"

if [ ! -f "$PHPUNIT_BIN" ]; then
    echo -e "${YELLOW}⬇️  Téléchargement de PHPUnit v$PHPUNIT_VERSION...${RESET}"
    curl -sL -o "$PHPUNIT_BIN" "$PHPUNIT_URL"
    chmod +x "$PHPUNIT_BIN"
    echo "$PHP_VERSION" > "$PHPUNIT_META_FILE"
    echo -e "${GREEN}✅ PHPUnit $PHPUNIT_VERSION installé.${RESET}"
else
    echo -e "${GREEN}✅ PHPUnit $PHPUNIT_VERSION déjà présent.${RESET}"
fi

EXIT_CODE=0


# ▶ PHPUnit
echo -e "${BLUE}▶ Tests PHPUnit...${RESET}"
if [ -f phpunit.xml ] || [ -f phpunit.xml.dist ]; then
    "$PHPUNIT_BIN" --teamcity | tee /tmp/phpunit.log
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        echo -e "${RED}❌ Des tests ont échoué.${RESET}"
        EXIT_CODE=1
    else
        echo -e "${GREEN}✅ Tous les tests sont passés.${RESET}"
    fi
else
    echo -e "${YELLOW}⚠️  Aucun fichier phpunit.xml trouvé, tests ignorés.${RESET}"
fi

# 🧾 Résumé
echo -e "${BLUE}---------------------------------------${RESET}"
if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les contrôles sont passés avec succès.${RESET}"
else
    echo -e "${RED}❌ Des erreurs ont été détectées. Corrigez-les avant de committer.${RESET}"
fi
echo -e "${BLUE}---------------------------------------${RESET}"

exit $EXIT_CODE

