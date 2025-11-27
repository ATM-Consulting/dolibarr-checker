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
#
# OPTIONS DISPONIBLES (variables d'environnement) :
# - VALIDATE_ALL=1       : Valider TOUS les fichiers du module (pas seulement les modifiés)
# - SKIP_HOOKS="hook1,hook2" : Ignorer certains hooks (ex: SKIP_HOOKS="codespell,sqlfluff-lint")
# - EXCLUDE_DIRS="dir1,dir2" : Exclure des répertoires (ex: EXCLUDE_DIRS="lib,vendor")
# - VERBOSE=1            : Mode verbeux avec plus de détails
#
# EXEMPLES D'UTILISATION :
# git commit -m "message"                                    # Mode standard
# VALIDATE_ALL=1 git commit -m "message"                     # Tous les fichiers
# SKIP_HOOKS="sqlfluff-lint" git commit -m "message"         # Ignorer sqlfluff
# EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "message"  # Tous sauf lib/
# ==============================================================================

# --- Variables de couleur et d'état ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

EXIT_CODE=0
START_TIME=$(date +%s)
LOG_FILE=$(mktemp)
PERSISTENT_LOG_DIR="$HOME/.dolibarr-checker/logs"
PERSISTENT_LOG_FILE=""
PERSISTENT_ERRORS_FILE=""

# Hooks ignorés par défaut (codespell car vérifie l'anglais)
DEFAULT_SKIP_HOOKS="codespell"

# --- Nettoyage à la sortie du script ---
cleanup() {
    if [[ -z "${VERBOSE}" ]]; then
        echo -e "${BLUE}▶ Nettoyage des fichiers temporaires...${RESET}"
    fi
    
    if [ -d "$MODULE_PATH/dev" ]; then
        rm -r "$MODULE_PATH/dev"
        rm -f "$MODULE_PATH/.pre-commit-config.yaml"
        rm -f "$MODULE_PATH/.sqlfluff"
        if [[ -z "${VERBOSE}" ]]; then
            echo -e "${GREEN}✅ Fichiers de configuration temporaires supprimés.${RESET}"
        fi
    fi
    
    # Sauvegarder les logs si des erreurs ont été détectées
    if [ "$EXIT_CODE" -ne 0 ] && [ -n "$PERSISTENT_LOG_FILE" ]; then
        # Sauvegarder le log complet
        cp "$LOG_FILE" "$PERSISTENT_LOG_FILE"
        
        # Créer un fichier d'erreurs formaté et lisible
        if [ -n "$PERSISTENT_ERRORS_FILE" ]; then
            # Créer le fichier d'erreurs formaté
            {
                echo "═══════════════════════════════════════════════════════════"
                echo "📋 RAPPORT D'ERREURS - $(date '+%Y-%m-%d %H:%M:%S')"
                echo "Module: $(basename "$MODULE_PATH")"
                echo "═══════════════════════════════════════════════════════════"
                echo ""
                
                # Section 1: Statistiques globales
                echo "📊 STATISTIQUES"
                echo "───────────────────────────────────────────────────────────"
                
                php_errors=$(grep -c "error -" "$LOG_FILE" 2>/dev/null || echo "0")
                sql_fails=$(grep -c "FAIL" "$LOG_FILE" 2>/dev/null || echo "0")
                yaml_errors=$(grep -c "yamllint" "$LOG_FILE" 2>/dev/null || echo "0")
                
                [ "$php_errors" -gt 0 ] && echo "  • Erreurs PHP CodeSniffer : $php_errors"
                [ "$sql_fails" -gt 0 ] && echo "  • Fichiers SQL en échec : $sql_fails"
                [ "$yaml_errors" -gt 0 ] && echo "  • Erreurs YAML : $yaml_errors"
                
                echo ""
                
                # Section 2: Erreurs PHP détaillées
                if [ "$php_errors" -gt 0 ]; then
                    echo "═══════════════════════════════════════════════════════════"
                    echo "🐘 ERREURS PHP"
                    echo "═══════════════════════════════════════════════════════════"
                    echo ""
                    
                    # Extraire et formater les erreurs PHP
                    grep "error -" "$LOG_FILE" | while IFS= read -r line; do
                        # Extraire les informations
                        file=$(echo "$line" | cut -d: -f1)
                        linenum=$(echo "$line" | cut -d: -f2)
                        colnum=$(echo "$line" | cut -d: -f3)
                        error_msg=$(echo "$line" | cut -d- -f2- | xargs)
                        
                        # Formater de manière lisible
                        echo "📄 Fichier: $(basename "$file")"
                        echo "   Ligne $linenum, Colonne $colnum"
                        echo "   ❌ $error_msg"
                        echo ""
                    done
                fi
                
                # Section 3: Erreurs SQL détaillées
                if [ "$sql_fails" -gt 0 ]; then
                    echo "═══════════════════════════════════════════════════════════"
                    echo "🗄️  ERREURS SQL"
                    echo "═══════════════════════════════════════════════════════════"
                    echo ""
                    
                    # Extraire les fichiers SQL en échec
                    current_file=""
                    grep -E "(FAIL|L:|P:)" "$LOG_FILE" | sed 's/\x1b\[[0-9;]*m//g' | while IFS= read -r line; do
                        if [[ "$line" =~ "FAIL" ]]; then
                            current_file=$(echo "$line" | grep -oP '\[.*?\]' | tr -d '[]')
                            echo "📄 Fichier: $current_file"
                            echo "   Erreurs détectées:"
                        elif [[ "$line" =~ "L:" ]]; then
                            # Extraire et traduire l'erreur SQL
                            line_num=$(echo "$line" | grep -oP 'L:\s*\K\d+')
                            pos=$(echo "$line" | grep -oP 'P:\s*\K\d+')
                            code=$(echo "$line" | grep -oP '[A-Z]+\d+')
                            msg=$(echo "$line" | grep -oP '\|\s*\K.*' | head -1)
                            
                            # Traduction des codes d'erreur courants
                            case "$code" in
                                RF04) explanation="Mot-clé SQL réservé utilisé comme identifiant" ;;
                                CP01) explanation="Casse des mots-clés SQL incohérente" ;;
                                AL01) explanation="Problème d'alias de table" ;;
                                *) explanation="$msg" ;;
                            esac
                            
                            echo "   • Ligne $line_num, Position $pos [$code]"
                            echo "     → $explanation"
                        fi
                    done
                    echo ""
                fi
                
                # Section 4: Conseils
                echo "═══════════════════════════════════════════════════════════"
                echo "💡 CONSEILS POUR CORRIGER"
                echo "═══════════════════════════════════════════════════════════"
                echo ""
                echo "1. Erreurs PHP :"
                echo "   • Consultez chaque fichier et ligne indiqués"
                echo "   • Corrigez les problèmes de formatage et documentation"
                echo ""
                echo "2. Erreurs SQL :"
                echo "   • Option rapide : SKIP_HOOKS=\"sqlfluff-lint\" git commit"
                echo "   • Option propre : Renommez les colonnes utilisant des mots-clés réservés"
                echo ""
                echo "3. Pour ignorer temporairement :"
                echo "   git commit --no-verify (déconseillé)"
                echo ""
                echo "═══════════════════════════════════════════════════════════"
                
            } > "$PERSISTENT_ERRORS_FILE"
            
            if [ -s "$PERSISTENT_ERRORS_FILE" ]; then
                echo -e "${CYAN}📝 Log complet : $PERSISTENT_LOG_FILE${RESET}"
                echo -e "${YELLOW}⚠️  Rapport d'erreurs formaté : $PERSISTENT_ERRORS_FILE${RESET}"
            fi
        fi
    fi
    
    rm -f "$LOG_FILE"
}
trap cleanup EXIT

# --- 1. Détection du contexte d'exécution ---
if [[ -n "${VERBOSE}" ]]; then
    echo -e "${MAGENTA}[VERBOSE] Démarrage du script de validation...${RESET}"
fi

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

# Créer le répertoire de logs persistants
mkdir -p "$PERSISTENT_LOG_DIR"
MODULE_NAME=$(basename "$MODULE_PATH")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PERSISTENT_LOG_FILE="$PERSISTENT_LOG_DIR/${MODULE_NAME}_${TIMESTAMP}.log"
PERSISTENT_ERRORS_FILE="$PERSISTENT_LOG_DIR/${MODULE_NAME}_${TIMESTAMP}_errors.log"

# Afficher les options configurées
if [[ -n "${VERBOSE}" ]]; then
    echo -e "${MAGENTA}[VERBOSE] Options configurées :${RESET}"
    echo -e "${MAGENTA}  - Module : $MODULE_NAME${RESET}"
    echo -e "${MAGENTA}  - VALIDATE_ALL : ${VALIDATE_ALL:-non défini}${RESET}"
    echo -e "${MAGENTA}  - SKIP_HOOKS : ${SKIP_HOOKS:-$DEFAULT_SKIP_HOOKS (défaut)}${RESET}"
    echo -e "${MAGENTA}  - EXCLUDE_DIRS : ${EXCLUDE_DIRS:-non défini}${RESET}"
    echo -e "${MAGENTA}  - Log complet : $PERSISTENT_LOG_FILE${RESET}"
    echo -e "${MAGENTA}  - Log erreurs : $PERSISTENT_ERRORS_FILE${RESET}"
fi


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

# Configuration sqlfluff pour éviter l'erreur "No dialect was specified"
cat > "$MODULE_PATH/.sqlfluff" << 'EOF'
[sqlfluff]
dialect = mysql
templater = raw
exclude_rules = L003,L009,L016,L031,L034,L036,L044,L045,L046,L047,L048,L052,L059,L063,L064
max_line_length = 200
EOF

if [[ -n "${VERBOSE}" ]]; then
    echo -e "${MAGENTA}[VERBOSE] Configuration sqlfluff créée (dialecte: MySQL)${RESET}"
fi

# --- 3. Exécution de pre-commit ---
echo -e "${BLUE}▶ Lancement des vérifications pre-commit...${RESET}"

if ! command -v pre-commit &> /dev/null; then
    echo -e "${RED}❌ 'pre-commit' n'est pas installé. Exécutez 'pip install pre-commit'.${RESET}"
    exit 1
fi

# Construction de la liste des hooks à ignorer
SKIP_LIST="${SKIP_HOOKS:-$DEFAULT_SKIP_HOOKS}"
if [[ -n "${VERBOSE}" ]]; then
    echo -e "${MAGENTA}[VERBOSE] Hooks ignorés : $SKIP_LIST${RESET}"
fi

# Détection du mode d'exécution
PRECOMMIT_ARGS="--config \"$CONFIG_DEST_FILE\""

if [[ -n "${VALIDATE_ALL}" ]]; then
    echo -e "${YELLOW}🔍 Mode VALIDATE_ALL activé : vérification de TOUS les fichiers du module...${RESET}"
    PRECOMMIT_ARGS="--all-files $PRECOMMIT_ARGS"
    
    # Gestion de l'exclusion de répertoires en mode VALIDATE_ALL
    if [[ -n "${EXCLUDE_DIRS}" ]]; then
        echo -e "${YELLOW}📁 Exclusion des répertoires : ${EXCLUDE_DIRS}${RESET}"
        
        # Créer un fichier temporaire listant tous les fichiers sauf ceux exclus
        TEMP_FILE_LIST=$(mktemp)
        
        # Construire le pattern d'exclusion pour find
        EXCLUDE_PATTERN=""
        IFS=',' read -ra DIRS <<< "$EXCLUDE_DIRS"
        for dir in "${DIRS[@]}"; do
            dir=$(echo "$dir" | xargs) # Trim whitespace
            if [[ -z "$EXCLUDE_PATTERN" ]]; then
                EXCLUDE_PATTERN="-path ./$dir -prune"
            else
                EXCLUDE_PATTERN="$EXCLUDE_PATTERN -o -path ./$dir -prune"
            fi
        done
        
        # Lister tous les fichiers en excluant les répertoires spécifiés
        if [[ -n "$EXCLUDE_PATTERN" ]]; then
            eval "find . $EXCLUDE_PATTERN -o -type f -print" > "$TEMP_FILE_LIST"
        else
            find . -type f > "$TEMP_FILE_LIST"
        fi
        
        # Utiliser --files au lieu de --all-files
        PRECOMMIT_ARGS="--files \$(cat $TEMP_FILE_LIST | tr '\n' ' ') --config \"$CONFIG_DEST_FILE\""
        
        if [[ -n "${VERBOSE}" ]]; then
            FILE_COUNT=$(wc -l < "$TEMP_FILE_LIST")
            echo -e "${MAGENTA}[VERBOSE] Nombre de fichiers à vérifier : $FILE_COUNT${RESET}"
        fi
    fi
else
    echo -e "${BLUE}ℹ️  Mode standard : vérification des fichiers modifiés uniquement.${RESET}"
    echo -e "${BLUE}   💡 Astuce : VALIDATE_ALL=1 git commit -m \"message\" pour tout vérifier${RESET}"
fi

# Affichage de la commande en mode verbose
if [[ -n "${VERBOSE}" ]]; then
    echo -e "${MAGENTA}[VERBOSE] Commande pre-commit : SKIP=$SKIP_LIST pre-commit run $PRECOMMIT_ARGS${RESET}"
fi

# Exécution de pre-commit
eval "SKIP=$SKIP_LIST pre-commit run $PRECOMMIT_ARGS" | tee "$LOG_FILE"
PRECOMMIT_EXIT=${PIPESTATUS[0]}

# Nettoyage du fichier temporaire si créé
if [[ -n "${TEMP_FILE_LIST}" ]]; then
    rm -f "$TEMP_FILE_LIST"
fi

if [ "$PRECOMMIT_EXIT" -ne 0 ]; then
    echo -e "\n${RED}❌ Des erreurs ont été détectées par pre-commit.${RESET}"
    EXIT_CODE=1
else
    echo -e "\n${GREEN}✅ Tous les hooks pre-commit sont passés avec succès.${RESET}"
fi


# --- 4. Analyse et résumé des erreurs ---
if [ "$EXIT_CODE" -ne 0 ]; then
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}📊 ANALYSE DES ERREURS DÉTECTÉES${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${RESET}\n"
    
    # Compter les erreurs par type de hook
    declare -A error_counts
    
    # Analyse du log pour extraire les erreurs
    if grep -q "PHP Syntax Check" "$LOG_FILE"; then
        php_errors=$(grep -c "error -" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$php_errors" -gt 0 ]; then
            error_counts["PHP Syntax Check"]=$php_errors
        fi
    fi
    
    if grep -q "PHP CodeSniffer" "$LOG_FILE"; then
        phpcs_errors=$(grep -c "error -" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$phpcs_errors" -gt 0 ]; then
            error_counts["PHP CodeSniffer"]=$phpcs_errors
        fi
    fi
    
    if grep -q "sqlfluff-lint" "$LOG_FILE"; then
        sql_errors=$(grep -c "sqlfluff-lint" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$sql_errors" -gt 0 ]; then
            error_counts["SQL Lint"]=$sql_errors
        fi
    fi
    
    if grep -q "yamllint" "$LOG_FILE"; then
        yaml_errors=$(grep -c "yamllint" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$yaml_errors" -gt 0 ]; then
            error_counts["YAML Lint"]=$yaml_errors
        fi
    fi
    
    # Afficher le résumé des erreurs
    if [ ${#error_counts[@]} -gt 0 ]; then
        echo -e "${YELLOW}Erreurs détectées par hook :${RESET}"
        for hook in "${!error_counts[@]}"; do
            echo -e "  ${RED}▸${RESET} $hook : ${RED}${error_counts[$hook]}${RESET} erreur(s)"
        done
        echo ""
    fi
    
    # Conseils pour corriger
    echo -e "${CYAN}💡 CONSEILS POUR CORRIGER :${RESET}"
    echo -e "  ${BLUE}1.${RESET} Consultez les erreurs détaillées ci-dessus"
    echo -e "  ${BLUE}2.${RESET} Corrigez les fichiers concernés"
    echo -e "  ${BLUE}3.${RESET} Relancez : ${YELLOW}git commit${RESET}"
    echo -e "  ${BLUE}4.${RESET} Pour ignorer un hook : ${YELLOW}SKIP_HOOKS=\"nom_hook\" git commit${RESET}"
    echo -e "  ${BLUE}5.${RESET} Pour contourner totalement : ${YELLOW}git commit --no-verify${RESET} ${RED}(déconseillé)${RESET}"
    echo ""
fi

# --- 5. Résumé final ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "${CYAN}═══════════════════════════════════════════════════════════${RESET}"
if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "${GREEN}✅ VALIDATION RÉUSSIE${RESET}"
    echo -e "${GREEN}🎉 Tous les contrôles sont au vert !${RESET}"
else
    echo -e "${RED}❌ VALIDATION ÉCHOUÉE${RESET}"
    echo -e "${RED}Des erreurs doivent être corrigées avant de committer.${RESET}"
fi

echo -e "${CYAN}───────────────────────────────────────────────────────────${RESET}"
echo -e "${BLUE}⏱️  Temps d'exécution : ${DURATION}s${RESET}"

if [ "$EXIT_CODE" -ne 0 ]; then
    echo -e "${BLUE}📝 Log complet : ${PERSISTENT_LOG_FILE}${RESET}"
    if [ -s "$PERSISTENT_ERRORS_FILE" ]; then
        ERROR_COUNT=$(grep -c "error -\|FAIL" "$PERSISTENT_ERRORS_FILE" 2>/dev/null || echo "0")
        echo -e "${YELLOW}⚠️  Erreurs seules (${ERROR_COUNT} lignes) : ${PERSISTENT_ERRORS_FILE}${RESET}"
    fi
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${RESET}\n"

exit $EXIT_CODE