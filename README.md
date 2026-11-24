# DLL d’icônes pour Active Directory

Une bibliothèque Windows de ressources qui regroupe des icônes personnalisées pour les postes membres d’un domaine Active Directory. Les icônes intégrées peuvent être référencées par leur chemin dans les raccourcis Windows déployés avec une stratégie de groupe (GPO).

> Le dépôt fournit la base de compilation. Les fichiers `.ico` personnalisés sont à ajouter dans `assets/icons/` avant de produire une DLL contenant les icônes.

## Structure

```text
assets/icons/       Fichiers .ico source (un fichier par icône)
include/            En-têtes générés, dont les identifiants de ressources
src/                Point d’entrée minimal de la DLL
build/              Sortie locale de compilation (ignorée par Git)
```

Les noms de fichiers deviennent les noms de ressources : `server.ico` génère `ICON_SERVER`. Les identifiants numériques et noms symboliques sont générés dans `build/generated/resource_ids.h` et `build/generated/icons.rc`. Gardez les noms de fichiers uniques, simples et composés de lettres, chiffres, `_` ou `-`.

## Prérequis et compilation

- Windows 10/11 ou Windows Server.
- Visual Studio 2022 ou Visual Studio Build Tools 2022 avec la charge de travail **Desktop development with C++**, MSVC v143 et un Windows 10/11 SDK. Cette charge fournit le compilateur C++ et le compilateur de ressources Windows (`rc.exe`).
- CMake 3.24 ou ultérieur, disponible dans le `PATH`.
- PowerShell 5.1 ou PowerShell 7. VS Code est facultatif ; il sert d’éditeur et son terminal PowerShell peut lancer le script.

### Pilotage interactif

Depuis un terminal PowerShell ouvert à la racine du dépôt (dans VS Code : **Terminal → New Terminal**) :

```powershell
./scripts/Build-ADIcons.ps1
```

Choisissez **1** pour configurer et compiler en Release, puis sélectionnez l’architecture (`x64`, `Win32` ou `ARM64`). Le script affiche les identifiants générés à la fin. Choisissez **2** pour les afficher ultérieurement ou **3** pour ouvrir le dossier où déposer les icônes. Si la stratégie d’exécution PowerShell bloque le script, exécutez-le dans une session autorisée par votre organisation ; ne modifiez pas la stratégie machine uniquement pour ce dépôt.

Le script utilise le générateur Visual Studio 2022 de CMake. Si vous voyez une erreur indiquant que le générateur ou le compilateur est introuvable, installez les prérequis ci-dessus et redémarrez VS Code. L’ouverture de VS Code depuis **Developer PowerShell for VS 2022** initialise également l’environnement MSVC.

### Compilation manuelle

Dans un terminal **Developer PowerShell for VS 2022**, depuis la racine du dépôt :

```powershell
cmake -S . -B build -A x64
cmake --build build --config Release
```

La DLL est produite dans `build/bin/Release/AD-Icons.dll`. Pour une architecture différente, remplacer `x64` par `Win32` ou `ARM64` si le kit Windows installé la prend en charge. Ajoutez les fichiers `.ico` avant la configuration CMake ; relancez CMake après tout changement d’icônes. Le script interactif et les commandes manuelles utilisent le même répertoire `build` ; ne changez pas de générateur dans ce répertoire existant.

## Déploiement avec une GPO

1. Copiez la DLL depuis un emplacement de publication contrôlé vers un chemin stable sur chaque poste, par exemple `C:\ProgramData\Organisation\Icons\AD-Icons.dll`. La GPO **Computer Configuration → Preferences → Windows Settings → Folders/Files** peut créer le dossier et copier le fichier.
2. Créez ou modifiez un raccourci avec **User Configuration → Preferences → Windows Settings → Shortcuts**. Dans le champ de l’icône, utilisez le chemin local et l’identifiant de ressource, par exemple `C:\ProgramData\Organisation\Icons\AD-Icons.dll,1000`.
3. Consultez `build/generated/resource_ids.h` pour associer chaque icône à son identifiant. Les identifiants sont attribués dans l’ordre alphabétique des noms de fichiers ; gardez une copie de cet en-tête avec la version distribuée.
4. Testez la stratégie sur un groupe pilote et les architectures ciblées avant le déploiement général. Les raccourcis doivent référencer un chemin local présent sur le poste ; un chemin de partage réseau dépend de la disponibilité réseau et des permissions de l’utilisateur.

Windows lit directement les ressources de la DLL ; il n’est pas nécessaire d’enregistrer ou d’inscrire la bibliothèque avec `regsvr32`.

## Validation

La compilation du projet vérifie les ressources et produit la DLL. Pour valider une icône, ouvrez les propriétés d’un raccourci de test sur Windows et sélectionnez la ressource dans la DLL. Le dépôt ne contient pas encore les icônes personnalisées ; elles doivent être ajoutées avant cette validation fonctionnelle.

## Licence et provenance des icônes

Ajoutez une licence adaptée à votre organisation avant toute redistribution publique. Vérifiez les droits de redistribution des icônes ajoutées et documentez leur provenance.
