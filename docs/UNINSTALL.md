# Désinstallation

## Retirer AppDesk

AppDesk est portable. Attendez la fin de la file, fermez la fenêtre puis supprimez `MonInstallateur.exe`. Aucun service AppDesk ni tâche planifiée n’est créé.

Les sessions, journaux et outils téléchargés restent dans `%LOCALAPPDATA%/AppDesk/Sessions` ; les sélections restent dans `Documents/AppDesk/selection.json`. Vous pouvez supprimer ces données après avoir conservé les journaux nécessaires et vérifié qu’aucune installation n’est en cours. Les logiciels déjà installés ne seront pas retirés par cette suppression.

## Retirer les applications installées

Dans Windows, ouvrez **Paramètres → Applications → Applications installées**, choisissez le logiciel puis **Désinstaller**. Utilisez son assistant officiel et les droits administrateur demandés. Office et les clients VPN peuvent avoir des procédures spécifiques ; sauvegardez les profils ou données nécessaires avant leur retrait.

Pour une application reconnue par WinGet, la commande officielle `winget uninstall --id IDENTIFIANT --exact` est également possible. Vérifiez l’identifiant avec `winget list` avant d’agir. Cette documentation n’exécute aucune désinstallation automatiquement.

## Revenir sur un arrêt de file

L’arrêt AppDesk prend effet après l’application en cours. Il n’annule pas les applications déjà traitées et n’effectue aucun retour arrière global. Consultez le journal puis désinstallez individuellement les programmes que vous souhaitez retirer.
