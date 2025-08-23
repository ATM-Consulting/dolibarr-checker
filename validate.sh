#!/bin/bash

# ==============================================================================
# Script pour exécuter les hooks pre-commit de Dolibarr sur un module externe.
# Il simule l'exécution depuis la racine de Dolibarr en copiant
# temporairement la configuration nécessaire dans le module.

# Diverses infos :
# Pour lancer l'installation de ce script, il faut lancer le script ./install.sh
# Le script ne se lance que sur les fichiers modifiés présent dans un repertoire custom
# Le lancement de la partie codespell est cancel (qui vérifie que le code est bien en anglais)
# Il est possible d'ignorer le lancement de ce script en procédant à un git commit --no-verify
# ==============================================================================

# --- Variables de couleur et d'état ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
RESET='\033[0m'

EXIT_CODE=0
LOG_FILE=$(mktemp)

# --- Nettoyage à la sortie du script ---
cleanup() {
    echo -e "${BLUE}▶ Nettoyage des fichiers temporaires...${RESET}"
    if [ -d "$MODULE_PATH/dev" ]; then
        rm -r "$MODULE_PATH/dev"
        rm -f "$MODULE_PATH/.pre-commit-config.yaml" # Utiliser -f pour éviter une erreur si le fichier n'existe pas
        echo -e "${GREEN}✅ Fichiers de configuration temporaires supprimés.${RESET}"
    fi
    rm -f "$LOG_FILE"
}
trap cleanup EXIT


# --- 1. Détection du contexte d'exécution ---
echo -e "${BLUE}▶ Détection de l'environnement Dolibarr...${RESET}"
MODULE_PATH=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ "$?" -ne 0 || ! "$MODULE_PATH" == *"/custom/"* ]]; then
    echo -e "${YELLOW}⚠️  Ce script doit être lancé depuis un module Dolibarr situé dans custom/. Aucun test exécuté.${RESET}"
    exit 0
fi

HTDOCS_PATH=""
CURRENT_DIR="$MODULE_PATH"
while [[ "$CURRENT_DIR" != "/" ]]; do
    if [[ -f "$CURRENT_DIR/main.inc.php" ]]; then
        HTDOCS_PATH="$CURRENT_DIR"
        break
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

if [[ -z "$HTDOCS_PATH" ]]; then
    echo -e "${RED}❌ Impossible de localiser la racine de Dolibarr (contenant main.inc.php).${RESET}"
    exit 1
fi

DOLI_ROOT=$(dirname "$HTDOCS_PATH")
echo -e "${GREEN}✔️  Racine Dolibarr détectée : $DOLI_ROOT${RESET}"


# --- 2. Préparation de l'environnement de test ---
CONFIG_SOURCE_DIR="$DOLI_ROOT/dev"
CONFIG_SOURCE_FILE="$DOLI_ROOT/.pre-commit-config.yaml"
CONFIG_DEST_DIR="$MODULE_PATH/dev/"
CONFIG_DEST_FILE="$MODULE_PATH/.pre-commit-config.yaml"

echo -e "${BLUE}▶ Copie de la configuration pre-commit...${RESET}"
if [[ -d "$CONFIG_SOURCE_DIR" && -f "$CONFIG_SOURCE_FILE" ]]; then
    cp -r "$CONFIG_SOURCE_DIR" "$CONFIG_DEST_DIR"
    cp "$CONFIG_SOURCE_FILE" "$CONFIG_DEST_FILE"
    echo -e "${GREEN}✅ Configuration pre-commit copiée avec succès.${RESET}"
else
    echo -e "${RED}❌ Configuration pre-commit non trouvée dans $DOLI_ROOT.${RESET}"
    exit 1
fi

# 🚀 NOUVELLE LIGNE AJOUTÉE ICI 🚀
# On supprime la règle qui exclut le dossier /custom/ du fichier de règles copié.
sed -i.bak 's~<exclude-pattern>/htdocs/(custom|includes)/</exclude-pattern>~~g' "$CONFIG_DEST_DIR/setup/codesniffer/ruleset.xml" && rm "$CONFIG_DEST_DIR/setup/codesniffer/ruleset.xml.bak"
echo -e "${GREEN}✔️  Règle d'exclusion pour le dossier 'custom' retirée temporairement.${RESET}"


# --- 3. Exécution de pre-commit ---
echo -e "${BLUE}▶ Lancement des vérifications pre-commit...${RESET}"

if ! command -v pre-commit &> /dev/null; then
    echo -e "${RED}❌ 'pre-commit' n'est pas installé. Exécutez 'pip install pre-commit'.${RESET}"
    exit 1
fi

SKIP=codespell pre-commit run --config "$CONFIG_DEST_FILE" | tee "$LOG_FILE"
PRECOMMIT_EXIT=${PIPESTATUS[0]}

if [ "$PRECOMMIT_EXIT" -ne 0 ]; then
    echo -e "\n${RED}❌ Des erreurs ont été détectées par pre-commit.${RESET}"
    EXIT_CODE=1
else
    echo -e "\n${GREEN}✅ Tous les hooks pre-commit sont passés avec succès.${RESET}"
fi


# --- 4. Résumé final ---
echo -e "${BLUE}---------------------------------------${RESET}"
if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "${GREEN}🎉 Mission accomplie ! Tous les contrôles sont au vert.${RESET}"
else
    echo -e "${RED}❗️ Des erreurs ont été détectées. Merci de les corriger avant de committer.${RESET}"
    echo -e "${YELLOW}📄 Les détails sont disponibles dans le log ci-dessus.${RESET}"
fi
echo -e "${BLUE}---------------------------------------${RESET}"

exit $EXIT_CODE