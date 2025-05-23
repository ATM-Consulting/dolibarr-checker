#!/bin/bash

# on sais jamais :)
if ! command -v php &> /dev/null; then
    echo "PHP n'est pas installé o_o"
    exit 1
fi

# répertoire pour stocker les fichiers
TOOLS_DIR="$HOME/.dolibarr-checker/bin"
mkdir -p "$TOOLS_DIR"

# télécharger les outils qui ne sont pas trouvés
download_tool() {
    local tool_name=$1
    local download_url=$2
    local destination="$TOOLS_DIR/$tool_name"
    if ! command -v $tool_name &> /dev/null; then
        echo "$tool_name non trouvé, téléchargement depuis $download_url..."
        curl -L -o "$destination" "$download_url"
        chmod +x "$destination"
        echo "$tool_name installé localement dans $destination"
    else
        echo "$tool_name est déjà installé globalement."
    fi
}

# exemple avec phpunit

download_tool "phpunit" "https://phar.phpunit.de/phpunit.phar"

# Répertoire d'installation pour dolibarr-check
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ]; then
    echo "Pas de droits d'écriture sur $INSTALL_DIR. Installation dans le répertoire local."
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi


cp validate.sh "$INSTALL_DIR/dolibarr-check"
chmod +x "$INSTALL_DIR/dolibarr-check"
echo "Le script 'dolibarr-check' a été installé dans $INSTALL_DIR/dolibarr-check"

# hook global pour git
HOOKS_DIR="$HOME/.git-hooks"
mkdir -p "$HOOKS_DIR"

cp pre-commit "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "Le hook pre-commit a été installé dans $HOOKS_DIR/pre-commit"


git config --global core.hooksPath "$HOOKS_DIR"
echo "La configuration globale de Git a été mise à jour pour utiliser $HOOKS_DIR comme répertoire de hooks."

echo "Installation terminée. Tous les commits seront désormais vérifiés via dolibarr-check."


