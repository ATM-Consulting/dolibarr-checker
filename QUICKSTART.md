# 🚀 Quick Start - Dolibarr Checker

## Installation en 2 minutes

### 1. Installer pre-commit
```bash
pip install pre-commit
```

### 2. Installer le hook dans votre module
```bash
cd /chemin/vers/dolibarr/htdocs/custom/votre-module
/chemin/vers/dolibarr-checker/install.sh
```

### 3. C'est prêt ! ✅
```bash
git commit -m "votre message"
```

---

## 📝 Commandes essentielles

### Commit standard (fichiers modifiés)
```bash
git commit -m "fix: correction bug"
```

### Validation complète (tous les fichiers)
```bash
VALIDATE_ALL=1 git commit -m "refactor: nettoyage code"
```

### Ignorer sqlfluff (problèmes SQL)
```bash
SKIP_HOOKS="sqlfluff-lint" git commit -m "feat: ajout SQL"
```

### Exclure lib/ (bibliothèques tierces)
```bash
EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "chore: update lib"
```

### Mode debug
```bash
VERBOSE=1 git commit -m "debug: investigation"
```

---

## 🆘 Problèmes courants

### ❌ Erreur "No dialect was specified"
**Solution** : ✅ Résolu automatiquement dans la v2.0 !

### ❌ Trop d'erreurs dans lib/gantt/
**Solution** :
```bash
EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit -m "message"
```

### ❌ Je veux juste ignorer sqlfluff
**Solution** :
```bash
SKIP_HOOKS="sqlfluff-lint" git commit -m "message"
```

### ❌ Urgence, je dois committer maintenant !
**Solution** (déconseillé) :
```bash
git commit --no-verify -m "WIP: urgence"
```

---

## 💡 Astuces

### Alias recommandés
Ajoutez dans votre `~/.bashrc` :
```bash
alias gcv='VALIDATE_ALL=1 git commit'
alias gcs='SKIP_HOOKS="sqlfluff-lint" git commit'
alias gcl='EXCLUDE_DIRS="lib" VALIDATE_ALL=1 git commit'
```

Utilisation :
```bash
gcv -m "validation complète"
gcs -m "sans sqlfluff"
gcl -m "sans lib/"
```

### Voir les logs sauvegardés
```bash
ls -lh ~/.dolibarr-checker/logs/
```

### Nettoyer les vieux logs
```bash
find ~/.dolibarr-checker/logs/ -name "*.log" -mtime +30 -delete
```

---

## 📚 Documentation complète

- **README.md** : Guide complet d'utilisation
- **EXAMPLES.sh** : Exemples pratiques et cas d'usage
- **CHANGELOG.md** : Historique des versions
- **SUMMARY.md** : Résumé des améliorations v2.0

---

## 🎯 Workflow recommandé

### Développement quotidien
```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
```

### Avant de pousser
```bash
VALIDATE_ALL=1 git commit -m "feat: ready to push"
git push origin ma-branche
```

### Avant un merge request
```bash
VERBOSE=1 VALIDATE_ALL=1 git commit -m "feat: ready for review"
git push origin ma-branche
```

---

## ✅ C'est tout !

Vous êtes prêt à utiliser Dolibarr Checker ! 🎉

Pour plus de détails, consultez le **README.md**.
