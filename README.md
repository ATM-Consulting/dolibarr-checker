## Outil de Validation `dolibarr-check`

Ce dépôt contient les scripts nécessaires pour installer un *hook Git global* (`pre-commit`) qui valide le code de vos modules externes Dolibarr avant chaque *commit*.

### 1\. Installation

Le script `install.sh` installe la commande principale `dolibarr-check` et configure Git pour utiliser le *hook* `pre-commit` globalement.

#### Prérequis pour l'installation

Avant de lancer `install.sh`, assurez-vous de disposer des éléments suivants :

* **Logiciels Requis :**
    * `bash` (pour exécuter le script)
    * `php` (le script vérifie sa présence)
    * `git` (pour configurer les *hooks* globaux)
    * `curl` (pour télécharger des dépendances comme `phpunit`)
* **Fichiers Requis :**
  Le script `install.sh` doit être dans le même répertoire que les deux fichiers suivants :
    * `validate.sh` (qui deviendra la commande `dolibarr-check`)
    * `pre-commit` (le script de *hook* qui sera copié)

#### Procédure d'installation

1.  Rendez le script d'installation exécutable :
    ```bash
    chmod +x install.sh
    ```
2.  Lancez l'installation :
    ```bash
    ./install.sh
    ```
3.  **Vérification du `PATH` :**
    Si le script s'installe dans `$HOME/.local/bin` (parce que vous n'avez pas les droits sur `/usr/local/bin`), assurez-vous que ce répertoire est bien dans votre `PATH`. Ajoutez la ligne suivante à votre `~/.bashrc` ou `~/.zshrc` si ce n'est pas le cas :
    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

-----

### 2\. Fonctionnement et Prérequis d'Exécution

Une fois installé, le *hook* `pre-commit` s'exécutera automatiquement à chaque `git commit` sur n'importe quel dépôt de votre machine.

Ce *hook* est conçu pour valider spécifiquement les modules Dolibarr. Pour qu'il fonctionne correctement **au moment du *commit***, l'environnement de votre module doit respecter les points suivants.

#### Prérequis Logiciels (pour l'exécution)

* **Framework `pre-commit`** : L'outil principal utilisé pour lancer les vérifications.
    * *Installation (généralement)* : `pip install pre-commit`
* **Python & `pip`** : Nécessaires pour installer le framework `pre-commit`.

#### Structure de l'Environnement (Critique)

* **Dépôt Git** : Vous devez être en train de *commiter* dans un dépôt Git valide (votre module).
* **Emplacement du Module** : Votre module **doit** être situé dans un répertoire dont le chemin contient `/custom/`.
    * *Exemple valide* : `/var/www/dolibarr/htdocs/custom/monmodule`
    * *Exemple invalide* : `/home/dev/projets/monmodule`
* **Racine Dolibarr** : Le script doit pouvoir trouver la racine de votre installation Dolibarr (le répertoire `htdocs` contenant `main.inc.php`) en remontant depuis le dossier de votre module.

#### Fichiers de Configuration Dolibarr

Le *hook* simule une exécution depuis la racine de Dolibarr en copiant sa configuration. La racine de votre installation Dolibarr (le répertoire au-dessus de `htdocs`) **doit** donc contenir :

1.  Un fichier `.pre-commit-config.yaml`
2.  Un répertoire `dev/`
3.  Le fichier de règles `dev/setup/codesniffer/ruleset.xml`

#### Permissions

L'utilisateur effectuant le *commit* doit avoir les **droits d'écriture** à la racine de son propre module (là où se trouve le `.git/`). Le script a besoin de créer et supprimer temporairement un dossier `dev/` et un fichier `.pre-commit-config.yaml` dans ce dossier.