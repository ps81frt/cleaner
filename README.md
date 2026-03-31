# Cleaner v2.0 - Windows System Optimization Tool

## Description

**Cleaner** est un utilitaire de nettoyage industriel pour Windows, développé en PowerShell avec une interface graphique WPF asynchrone. Conçu pour les ingénieurs système, il optimise les performances en ciblant les résidus profonds du système d'exploitation.

## Caractéristiques Techniques

*   **Interface WPF (XAML) :** Une UI fluide et responsive, utilisant un thème sombre moderne (Catppuccin-like).

*   **Architecture Runspaces :** Utilisation du multi-threading pour séparer la logique de nettoyage (Worker thread) du thread de l'interface utilisateur (UI thread). L'interface reste fluide même lors de suppressions massives.

*   **Optimisation .NET I/O :** Utilisation des méthodes .NET natives (`[System.IO.Directory]`, `[System.IO.File]`) au lieu des cmdlets standards pour un gain de performance massif sur les gros volumes de fichiers.

*   **Élévation de Privilèges :** Logique d'auto-élévation intégrée gérant les chemins d'accès complexes (espaces).

*   **Rapports Automatiques :** Génération d'un rapport complet (`.txt`) sur le bureau de l'utilisateur à la fin de chaque nettoyage, listant chaque élément supprimé.

*   **Sécurité Opérationnelle :** Protection contre les plantages d'Explorer et gestion sécurisée des erreurs d'accès fichiers.

## Détails Techniques des Interventions

Le script exécute des opérations de maintenance profonde structurées comme suit :

### 1. Optimisation du Magasin des Composants (WinSxS)

*   **Mécanisme :** Appel à l'API Deployment Image Servicing and Management via `Dism.exe /online /Cleanup-Image /StartComponentCleanup`.

*   **Impact :** Contrairement à une simple suppression, cette commande réduit la taille du répertoire `%SystemRoot%\WinSxS` en désinstallant les versions obsolètes (superseded) des composants Windows. 

*   **Note Ingénieur :** Cette opération est transactionnelle et définitive. Une fois effectuée, les mises à jour précédentes ne peuvent plus être désinstallées.

### 2. Nettoyage de la Télémétrie et Diagnostic (WER)

*   **Composants :** Cible les répertoires `%LOCALAPPDATA%\Microsoft\Windows\WER\` et `%ProgramData\Microsoft\Windows\WER\`.

*   **Actions :** Suppression des rapports d'erreurs archivés, des files d'attente de rapports et des fichiers de dump mémoire (`.dmp`) générés lors de crashs applicatifs. 

*   **Bénéfice :** Libération de volumes massifs de données souvent ignorés par les outils de nettoyage standards.

### 3. Purge des Traces d'Activité (Forensics & Privacy)

*   **UserAssist :** Suppression des entrées dans `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist`. Windows y stocke le nombre de lancements et la date de dernière utilisation des programmes GUI (encodés en ROT13).

*   **BAM/DAM (Background Activity Moderator) :** Nettoyage des ruches `HKLM\SYSTEM\CurrentControlSet\Services\bam` et `dam`. Ces composants surveillent les exécutables pour gérer les états d'alimentation. Leur purge réinitialise l'historique de monitoring du système.

*   **Prefetch :** Vidage de `%SystemRoot%\Prefetch`. Réinitialise les fichiers `.pf` utilisés pour accélérer le chargement des applications, utile pour résoudre des problèmes de corruption logicielle.

### 4. Maintenance des Piles de Mise à Jour (Windows Update)
*   **Workflow :** Arrêt forcé des services `wuauserv` (Windows Update), `bits` (Background Intelligent Transfer Service), `cryptsvc` (Cryptographic Services) et `msiserver` (Windows Installer).
*   **Cible :** Purge intégrale de `%SystemRoot%\SoftwareDistribution` (DataStore et Download) et `%SystemRoot%\System32\catroot2`. 
*   **Bénéfice :** Réparation des bases de données de mise à jour corrompues et libération de l'espace occupé par les installeurs déjà appliqués.

### 5. Caches des Navigateurs et Web-Stack
*   **Targets :** Profils par défaut de Microsoft Edge et Google Chrome dans `%LOCALAPPDATA%`.
*   **Contenu :** Suppression du `Cache`, `Code Cache`, `GPUCache` et `Media Cache`. 
*   **Réseau :** Exécution de `ipconfig /flushdns` (Resolver Cache) et `arp -d *` (Address Resolution Protocol table) pour purger les routes et résolutions obsolètes.

### 6. Caches Graphiques et Interface
*   **DirectX Shader Cache :** Suppression des shaders pré-compilés par le GPU. Crucial pour corriger les artefacts graphiques ou les saccades après une mise à jour de driver.
*   **Shell Icon/Thumb Cache :** Suppression des bases de données `.db` de l'explorateur. Nécessite le kill du processus `explorer.exe` pour libérer les handles sur les fichiers avant suppression.

### 7. Maintenance des Journaux (EventLogs & CBS)
*   **CBS (Component Based Servicing) :** Nettoyage des logs de maintenance Windows Update souvent très volumineux.
*   **EventLogs :** Vidage via `wevtutil.exe` des journaux *Application* et *Système*. Réduit la taille des fichiers `.evtx`.

## Variables de Configuration
Le script est conçu pour être facilement maintenable. Tous les chemins de nettoyage et les paramètres globaux sont définis dans la section `Variables / Config` en haut du fichier `Cleaner.ps1`.

## Installation et Utilisation
1.  Clonez le dépôt : `git clone https://github.com/ps81frt/cleaner`

2.  **Autoriser uniquement ce script (Sécurisé) :**
    Pour permettre l'exécution de ce fichier spécifique sans changer la sécurité globale de Windows, exécutez cette commande en Administrateur :
    ```powershell
    Unblock-File -Path "C:\Program Files\Cleaner\Cleaner.ps1"
    ```
3.  **Ajout au Menu Démarrer (Optionnel) :**
    Pour accéder facilement à l'outil, créez un raccourci pointant vers :
    `powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Program Files\Cleaner\Cleaner.ps1"`
    Placez ce raccourci dans : `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\`

4.  **Note :** Les privilèges Administrateur sont requis pour le nettoyage système.

## Informations Projet
*   **Auteur :** ps81frt
*   **Version :** 2.0
*   **GitHub :** https://github.com/ps81frt/cleaner

## Licence MIT

Copyright (c) 2026 ps81frt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---
*Disclaimer: Cet outil est destiné à un usage averti. L'auteur ne peut être tenu responsable des pertes de données liées à une mauvaise utilisation ou à la suppression de fichiers cache spécifiques.*
