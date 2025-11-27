# Changelog - Dolibarr Checker

## Version 2.0.0 - 2025-11-27

### 🎉 Nouvelles fonctionnalités

#### Options via variables d'environnement
- **VALIDATE_ALL=1** : Valider tous les fichiers du module (pas seulement les modifiés)
- **SKIP_HOOKS="hook1,hook2"** : Ignorer certains hooks spécifiques
- **EXCLUDE_DIRS="dir1,dir2"** : Exclure des répertoires de la validation (utile pour lib/, vendor/)
- **VERBOSE=1** : Mode verbeux avec informations de debug détaillées

#### Améliorations du résumé
- ✅ Analyse automatique des erreurs par type de hook
- ✅ Comptage des erreurs pour chaque hook
- ✅ Affichage du temps d'exécution
- ✅ Conseils contextuels pour corriger les erreurs
- ✅ Interface visuelle améliorée avec bordures et icônes

#### Logs persistants
- ✅ Sauvegarde automatique des logs en cas d'erreur
- ✅ Emplacement : `~/.dolibarr-checker/logs/`
- ✅ Format : `{nom_module}_{timestamp}.log`
- ✅ Affichage du chemin du log sauvegardé

#### Configuration sqlfluff
- ✅ Création automatique du fichier `.sqlfluff`
- ✅ Configuration du dialecte MySQL par défaut
- ✅ Exclusion de règles trop strictes
- ✅ Résout l'erreur "No dialect was specified"

### 🔧 Améliorations techniques

#### Gestion des hooks
- Hooks ignorés par défaut : `codespell` (vérifie l'anglais)
- Possibilité d'ignorer des hooks supplémentaires via `SKIP_HOOKS`
- Affichage de la liste des hooks ignorés en mode verbose

#### Exclusion de répertoires
- Utilisation de `find` avec patterns d'exclusion
- Support de plusieurs répertoires séparés par des virgules
- Comptage des fichiers à vérifier en mode verbose

#### Nettoyage
- Suppression du fichier `.sqlfluff` temporaire
- Nettoyage silencieux en mode non-verbose
- Messages conditionnels selon le mode

#### Interface utilisateur
- Nouvelles couleurs : CYAN, MAGENTA
- Bordures stylisées avec caractères Unicode
- Messages d'aide contextuels
- Icônes pour une meilleure lisibilité

### 📚 Documentation
- ✅ README.md complet avec exemples d'utilisation
- ✅ Documentation des options dans l'en-tête du script
- ✅ Exemples de commandes pour chaque cas d'usage
- ✅ Section de résolution de problèmes

### 🐛 Corrections de bugs
- ✅ Correction de l'erreur sqlfluff "No dialect was specified"
- ✅ Gestion correcte des fichiers temporaires
- ✅ Meilleure gestion des erreurs de pre-commit

---

## Version 1.0.0 - Date antérieure

### Fonctionnalités initiales
- Exécution des hooks pre-commit de Dolibarr sur modules custom
- Copie temporaire de la configuration depuis la racine Dolibarr
- Suppression de l'exclusion du dossier custom dans ruleset.xml
- Nettoyage automatique des fichiers temporaires
- Support de `git commit --no-verify` pour contourner
- Détection automatique de l'environnement Dolibarr
- Vérification que le script est lancé depuis custom/

---

## Roadmap (futures versions)

### Version 2.1.0 (à venir)
- [ ] Support de fichiers de configuration personnalisés
- [ ] Mode interactif pour choisir les hooks à exécuter
- [ ] Intégration avec les IDE (VSCode, PHPStorm)
- [ ] Rapport HTML des erreurs
- [ ] Auto-fix pour certaines erreurs simples

### Version 3.0.0 (à venir)
- [ ] Support de pre-commit hooks personnalisés par module
- [ ] Intégration CI/CD (GitLab CI, GitHub Actions)
- [ ] Dashboard web pour visualiser l'historique des validations
- [ ] Notifications (email, Slack, etc.)
