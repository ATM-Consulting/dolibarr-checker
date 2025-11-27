#!/bin/bash

# ==============================================================================
# EXEMPLES D'UTILISATION - Dolibarr Checker
# ==============================================================================
# Ce fichier contient des exemples pratiques d'utilisation du script validate.sh
# Copiez-collez les commandes selon vos besoins
# ==============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 1. UTILISATION BASIQUE
# ─────────────────────────────────────────────────────────────────────────────

# Commit standard (fichiers modifiés uniquement)
git commit -m "fix: correction bug affichage"

# Commit avec --no-verify (contourne la validation - DÉCONSEILLÉ)
git commit --no-verify -m "WIP: travail en cours"


# ─────────────────────────────────────────────────────────────────────────────
# 2. VALIDATION COMPLÈTE
# ─────────────────────────────────────────────────────────────────────────────

# Valider TOUS les fichiers du module
VALIDATE_ALL=1 git commit -m "refactor: nettoyage complet du code"

# Valider tous les fichiers en mode verbeux
VERBOSE=1 VALIDATE_ALL=1 git commit -m "feat: nouvelle fonctionnalité"


# ─────────────────────────────────────────────────────────────────────────────
# 3. IGNORER DES HOOKS SPÉCIFIQUES
# ─────────────────────────────────────────────────────────────────────────────

# Ignorer sqlfluff (problèmes avec SQL)
SKIP_HOOKS="sqlfluff-lint" git commit -m "feat: ajout requêtes SQL"

# Ignorer plusieurs hooks
SKIP_HOOKS="sqlfluff-lint,yamllint" git commit -m "chore: mise à jour config"

# Ignorer tous les hooks sauf PHP Syntax Check
SKIP_HOOKS="codespell,sqlfluff-lint,yamllint" git commit -m "fix: correction syntaxe"


# ─────────────────────────────────────────────────────────────────────────────
# 4. EXCLURE DES RÉPERTOIRES
# ─────────────────────────────────────────────────────────────────────────────

# Exclure le dossier lib/ (bibliothèques tierces)
EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "feat: ajout bibliothèque externe"

# Exclure plusieurs dossiers
EXCLUDE_DIRS="lib,vendor,node_modules" VALIDATE_ALL=1 git commit -m "chore: mise à jour dépendances"

# Exclure lib/ et ignorer sqlfluff
EXCLUDE_DIRS="lib" SKIP_HOOKS="sqlfluff-lint" VALIDATE_ALL=1 git commit -m "feat: nouvelle feature"


# ─────────────────────────────────────────────────────────────────────────────
# 5. MODE DEBUG / VERBOSE
# ─────────────────────────────────────────────────────────────────────────────

# Mode verbeux pour voir tous les détails
VERBOSE=1 git commit -m "debug: investigation problème"

# Mode verbeux + validation complète
VERBOSE=1 VALIDATE_ALL=1 git commit -m "test: validation complète"

# Mode verbeux + exclusions + skip hooks
VERBOSE=1 EXCLUDE_DIRS="lib" SKIP_HOOKS="sqlfluff-lint" VALIDATE_ALL=1 git commit -m "debug: test complet"


# ─────────────────────────────────────────────────────────────────────────────
# 6. CAS D'USAGE RÉELS
# ─────────────────────────────────────────────────────────────────────────────

# Avant un merge dans main
VALIDATE_ALL=1 git commit -m "feat: fonctionnalité complète et testée"

# Module avec bibliothèque Gantt (lib/gantt/)
EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "feat: intégration Gantt"

# Problème avec fichiers SQL legacy
SKIP_HOOKS="sqlfluff-lint" git commit -m "fix: correction migration SQL"

# Commit rapide en développement (fichiers modifiés seulement)
git commit -m "WIP: travail en cours"

# Validation finale avant release
VERBOSE=1 VALIDATE_ALL=1 git commit -m "release: version 1.2.0"

# Module avec vendor/ et node_modules/
EXCLUDE_DIRS="vendor,node_modules,lib" VALIDATE_ALL=1 git commit -m "chore: update dependencies"


# ─────────────────────────────────────────────────────────────────────────────
# 7. WORKFLOW RECOMMANDÉ
# ─────────────────────────────────────────────────────────────────────────────

# Développement quotidien
git add .
git commit -m "feat: nouvelle fonctionnalité"

# Avant de pousser sur origin
git add .
VALIDATE_ALL=1 git commit -m "feat: fonctionnalité complète"
git push origin ma-branche

# Avant un merge request / pull request
git add .
VERBOSE=1 VALIDATE_ALL=1 git commit -m "feat: ready for review"
git push origin ma-branche


# ─────────────────────────────────────────────────────────────────────────────
# 8. GESTION DES ERREURS
# ─────────────────────────────────────────────────────────────────────────────

# Si vous avez des erreurs, consultez le log sauvegardé
cat ~/.dolibarr-checker/logs/monmodule_*.log | tail -n 100

# Lister tous les logs sauvegardés
ls -lh ~/.dolibarr-checker/logs/

# Supprimer les anciens logs (plus de 30 jours)
find ~/.dolibarr-checker/logs/ -name "*.log" -mtime +30 -delete


# ─────────────────────────────────────────────────────────────────────────────
# 9. ALIAS BASH RECOMMANDÉS
# ─────────────────────────────────────────────────────────────────────────────

# Ajoutez ces alias dans votre ~/.bashrc ou ~/.zshrc

# Commit avec validation complète
alias gcv='VALIDATE_ALL=1 git commit'

# Commit sans sqlfluff
alias gcs='SKIP_HOOKS="sqlfluff-lint" git commit'

# Commit en excluant lib/
alias gcl='EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit'

# Commit en mode verbeux
alias gcvv='VERBOSE=1 git commit'

# Commit validation complète + verbeux
alias gcfull='VERBOSE=1 VALIDATE_ALL=1 git commit'

# Exemples d'utilisation des alias :
# gcv -m "feat: nouvelle fonctionnalité"
# gcs -m "fix: correction SQL"
# gcl -m "chore: mise à jour lib"


# ─────────────────────────────────────────────────────────────────────────────
# 10. SCRIPTS UTILES
# ─────────────────────────────────────────────────────────────────────────────

# Fonction pour valider sans committer
validate_only() {
    git add .
    VALIDATE_ALL=1 git commit -m "temp" --dry-run
    git reset HEAD
}

# Fonction pour voir les statistiques des logs
log_stats() {
    echo "📊 Statistiques des logs de validation :"
    echo "Nombre total de logs : $(ls ~/.dolibarr-checker/logs/*.log 2>/dev/null | wc -l)"
    echo "Dernier log : $(ls -t ~/.dolibarr-checker/logs/*.log 2>/dev/null | head -1)"
    echo "Taille totale : $(du -sh ~/.dolibarr-checker/logs/ 2>/dev/null | cut -f1)"
}

# Fonction pour nettoyer les vieux logs
clean_old_logs() {
    local days=${1:-30}
    echo "🧹 Nettoyage des logs de plus de $days jours..."
    find ~/.dolibarr-checker/logs/ -name "*.log" -mtime +$days -delete
    echo "✅ Nettoyage terminé"
}


# ─────────────────────────────────────────────────────────────────────────────
# 11. INTÉGRATION CI/CD
# ─────────────────────────────────────────────────────────────────────────────

# Exemple pour GitLab CI (.gitlab-ci.yml)
# validate:
#   script:
#     - cd htdocs/custom/monmodule
#     - VALIDATE_ALL=1 /path/to/dolibarr-checker/validate.sh
#   only:
#     - merge_requests

# Exemple pour GitHub Actions (.github/workflows/validate.yml)
# - name: Validate code
#   run: |
#     cd htdocs/custom/monmodule
#     VALIDATE_ALL=1 /path/to/dolibarr-checker/validate.sh


# ─────────────────────────────────────────────────────────────────────────────
# 12. TROUBLESHOOTING
# ─────────────────────────────────────────────────────────────────────────────

# Vérifier que pre-commit est installé
which pre-commit

# Vérifier la version de pre-commit
pre-commit --version

# Réinstaller le hook si nécessaire
cd /path/to/dolibarr-checker
./install.sh

# Tester le script manuellement
cd htdocs/custom/monmodule
/path/to/dolibarr-checker/validate.sh

# Voir les hooks pre-commit installés
cat .git/hooks/pre-commit

# Désinstaller le hook
rm .git/hooks/pre-commit
