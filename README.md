# 🔍 Dolibarr Checker - Script de Validation

Script pour exécuter les hooks pre-commit de Dolibarr sur un module externe situé dans `custom/`.

## 📋 Prérequis

- **Git** : Le module doit être dans un dépôt Git
- **Python** : Pour installer pre-commit
- **pre-commit** : `pip install pre-commit`
- **Dolibarr** : Le module doit être dans `htdocs/custom/`

## 🚀 Installation

```bash
cd /chemin/vers/votre/module/custom/monmodule
/chemin/vers/dolibarr-checker/install.sh
```

Cela configurera le hook pre-commit pour votre module.

## 💡 Utilisation

### Mode standard (fichiers modifiés uniquement)
```bash
git commit -m "votre message"
```

### Options avancées

#### 1. Valider TOUS les fichiers du module
```bash
VALIDATE_ALL=1 git commit -m "validation complète"
```

#### 2. Ignorer certains hooks
```bash
# Ignorer sqlfluff
SKIP_HOOKS="sqlfluff-lint" git commit -m "message"

# Ignorer plusieurs hooks
SKIP_HOOKS="sqlfluff-lint,yamllint" git commit -m "message"
```

#### 3. Exclure des répertoires
```bash
# Exclure le dossier lib/
EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "message"

# Exclure plusieurs dossiers
EXCLUDE_DIRS="lib,vendor,node_modules" VALIDATE_ALL=1 git commit -m "message"
```

#### 4. Mode verbeux (debug)
```bash
VERBOSE=1 git commit -m "message"
```

#### 5. Combinaison d'options
```bash
# Valider tous les fichiers sauf lib/, en mode verbeux, sans sqlfluff
VERBOSE=1 EXCLUDE_DIRS="lib" SKIP_HOOKS="sqlfluff-lint" VALIDATE_ALL=1 git commit -m "message"
```

#### 6. Contourner complètement la validation (déconseillé)
```bash
git commit --no-verify -m "message"
```

## 🔧 Hooks disponibles

Le script exécute les hooks suivants (sauf ceux ignorés) :

- **PHP Syntax Check** : Vérification de la syntaxe PHP
- **PHP CodeSniffer** : Respect des standards de code Dolibarr
- **sqlfluff-lint** : Validation des fichiers SQL (dialecte MySQL)
- **yamllint** : Validation des fichiers YAML
- **codespell** : Vérification orthographique (ignoré par défaut)

## 📊 Résumé des erreurs

En cas d'erreur, le script affiche :

- ✅ Un résumé des erreurs par type de hook
- ✅ Le nombre d'erreurs détectées
- ✅ Des conseils pour corriger
- ✅ Le temps d'exécution
- ✅ L'emplacement du log sauvegardé

### Exemple de sortie

```
═══════════════════════════════════════════════════════════
📊 ANALYSE DES ERREURS DÉTECTÉES
═══════════════════════════════════════════════════════════

Erreurs détectées par hook :
  ▸ PHP CodeSniffer : 12 erreur(s)
  ▸ PHP Syntax Check : 3 erreur(s)

💡 CONSEILS POUR CORRIGER :
  1. Consultez les erreurs détaillées ci-dessus
  2. Corrigez les fichiers concernés
  3. Relancez : git commit
  4. Pour ignorer un hook : SKIP_HOOKS="nom_hook" git commit
  5. Pour contourner totalement : git commit --no-verify (déconseillé)

═══════════════════════════════════════════════════════════
❌ VALIDATION ÉCHOUÉE
Des erreurs doivent être corrigées avant de committer.
───────────────────────────────────────────────────────────
⏱️  Temps d'exécution : 15s
📝 Log sauvegardé : /home/user/.dolibarr-checker/logs/monmodule_20251127_102030.log
═══════════════════════════════════════════════════════════
```

## 📁 Logs persistants

Les logs sont automatiquement sauvegardés en cas d'erreur dans :
```
~/.dolibarr-checker/logs/
```

Format du nom : `{nom_module}_{timestamp}.log`

## 🐛 Résolution de problèmes

### Erreur "No dialect was specified" (sqlfluff)
✅ **Résolu automatiquement** : Le script crée maintenant un fichier `.sqlfluff` avec le dialecte MySQL.

### Trop d'erreurs dans les bibliothèques tierces (lib/, vendor/)
✅ **Solution** : Utilisez `EXCLUDE_DIRS="lib,vendor"` pour les ignorer.

### Le script est trop lent
✅ **Solution** : En mode standard, seuls les fichiers modifiés sont vérifiés.

### Je veux juste ignorer sqlfluff
✅ **Solution** : `SKIP_HOOKS="sqlfluff-lint" git commit -m "message"`

## 🎯 Cas d'usage recommandés

| Situation | Commande recommandée |
|-----------|---------------------|
| Commit quotidien | `git commit -m "message"` |
| Validation complète avant merge | `VALIDATE_ALL=1 git commit -m "message"` |
| Module avec lib/ externe | `EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "message"` |
| Problème avec SQL | `SKIP_HOOKS="sqlfluff-lint" git commit -m "message"` |
| Debug du script | `VERBOSE=1 git commit -m "message"` |
| Urgence (à éviter) | `git commit --no-verify -m "message"` |

## 📝 Notes importantes

- Le script ne s'exécute que depuis un module dans `custom/`
- `codespell` est ignoré par défaut (vérifie que le code est en anglais)
- Les fichiers temporaires sont automatiquement nettoyés
- La configuration sqlfluff utilise le dialecte MySQL par défaut

## 🔄 Mise à jour

Pour mettre à jour le script :
```bash
cd /chemin/vers/dolibarr-checker
git pull
```

Puis réinstallez dans vos modules si nécessaire.

## 📄 Licence

Ce script utilise les hooks pre-commit de Dolibarr et suit les mêmes règles de validation que le core du projet.