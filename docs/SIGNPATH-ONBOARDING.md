# Préparer la candidature SignPath Foundation

Ce dossier prépare une candidature ; il ne crée pas de compte SignPath, ne publie pas de dépôt et n’envoie pas de formulaire. Le projet est récent : dépôt public, version stable 2.3.0 et préversions publiés ; aucune réputation publique établie ne peut encore être revendiquée. SignPath peut différer ou refuser la demande.

## 1. Publier et établir une première version

1. Propriétaire et dépôt publiés : `nico-TNS/appdesk`.
2. Créer le dépôt **public**, puis y publier le contenu de ce dossier sous licence MIT. Ne pas inclure `dist`, clés privées, journaux personnels ou packages d’éditeurs.
3. Confirmer les rôles de `MAINTAINERS.md`, activer la MFA et protéger `main`. Exiger les contrôles CI, la revue du code sensible et interdire les force-pushs. Ces réglages ne sont pas appliqués par les fichiers du dépôt.
4. Exécuter `Build and test` et examiner son journal, puis effectuer les essais réels dans un environnement autorisé. Ne pas désactiver une protection du poste pour faire passer les essais.
5. Créer une première release documentée à partir des sources revues, avec son binaire **explicitement non signé**, sa somme SHA-256 et les limites connues. Ne pas appeler cette release « signée ».
6. Tenir la documentation et le projet à jour et recueillir des retours authentiques. Ne pas inventer d’utilisateurs, de mainteneurs ou de réputation.

Le formulaire officiel est [Apply](https://signpath.org/apply.html). Lire les [conditions](https://signpath.org/terms.html), notamment celles concernant la maintenance, les releases, la réputation, la MFA et la provenance des builds. Les champs du formulaire peuvent changer ; le [brouillon anglais](SIGNPATH-APPLICATION-DRAFT.md) fournit les informations de fond à adapter.

## 2. Résoudre les points de revue technique

- Faire examiner le moteur PowerShell embarqué et sa politique de lancement décrits dans `SECURITY.md`. Une signature de l’EXE ne garantit pas à elle seule l’autorisation du script extrait.
- Valider les chemins de session, l’élévation, le contrôle du lanceur WinGet et la vérification des packages dans un test de sécurité adapté.
- Tester chaque installation silencieuse réellement, y compris les annulations et codes de redémarrage.
- Le package FortiClient VPN complet officiel a été téléchargé et installé silencieusement sur le poste de développement. Les connexions VPN restent à tester.
- Conserver des instructions de désinstallation et une politique de confidentialité à jour.

Présenter les limites restantes dans la candidature. Si SignPath exige une modification d’architecture ou un moteur natif, la réaliser avant une signature de production ; ne pas masquer le fonctionnement du moteur.

## 3. Configurer SignPath après acceptation

Dans SignPath, créer/lier le projet au dépôt GitHub public et au Trusted Build System GitHub.com. Installer l’application GitHub SignPath avec les droits nécessaires sur ce dépôt. Utiliser les noms et identifiants effectivement fournis par SignPath, sans deviner une organisation ni une politique.

Importer `signpath/artifact-configuration.xml`. Cette configuration cible uniquement l’EXE AppDesk contenu dans l’archive GitHub ; elle exige les métadonnées produit et une version explicite. Elle ne signe pas les packages Chrome, Office, VPN, etc. Valider la configuration dans l’éditeur SignPath avant de l’activer.

Créer la politique de production avec **approbation manuelle**. Affecter les rôles confirmés et activer la MFA. Garder le rôle de soumission du jeton aussi limité que possible. Ce dépôt ne contient aucun jeton ni certificat privé.

## 4. Configurer GitHub

Créer l’environnement `signpath-production` et lui ajouter un approbateur requis, lorsque le plan GitHub le permet. Avec un seul mainteneur, documenter cette situation ; ne pas prétendre disposer d’une revue indépendante. La demande doit aussi être approuvée manuellement dans SignPath.

Ajouter le **secret d’environnement** :

| Secret | Valeur |
| --- | --- |
| `SIGNPATH_API_TOKEN` | Jeton SignPath limité au rôle de soumission |

Ajouter les **variables de dépôt** suivantes après accord du fournisseur :

| Variable | Valeur |
| --- | --- |
| `SIGNPATH_ENABLED` | `true` uniquement après admission et configuration validée ; absent avant cela |
| `SIGNPATH_ORGANIZATION_ID` | Identifiant réel de l’organisation SignPath |
| `SIGNPATH_PROJECT_SLUG` | Slug réel du projet |
| `SIGNPATH_SIGNING_POLICY_SLUG` | Slug de la politique de production avec approbation manuelle |
| `SIGNPATH_ARTIFACT_CONFIGURATION_SLUG` | Slug de la configuration XML importée |
| `SIGNPATH_EXPECTED_PUBLISHER` | Nom de l’éditeur réellement accordé par SignPath, vérifié avec eux |

Ne jamais mettre ces secrets dans le code, un ticket ou une PR. Le jeton de signature n’est pas disponible dans la CI des PR. Les identifiants d’organisation et slugs ne sont pas des clés privées, mais doivent correspondre à la configuration réelle.

## 5. Première demande de signature

1. Lancer manuellement `SignPath production` depuis `main` revu.
2. Approuver l’environnement GitHub selon la politique configurée.
3. Examiner la provenance de l’artifact et approuver manuellement la demande dans SignPath.
4. Vérifier le résultat signé, son éditeur, la version et la nouvelle somme SHA-256.
5. Tester le candidat signé sur un poste Windows autorisé ; publier ensuite une release clairement identifiée.

Le workflow ne publie pas automatiquement de release. Les paramètres et la configuration XML ont été préparés et contrôlés localement ; le connecteur SignPath et les workflows nécessitent encore une validation réelle après publication/admission.

## Crédit de signature

Après acceptation seulement, activer la mention prévue dans `CODE_SIGNING.md` sur la page du projet et les pages de téléchargement. Jusqu’alors, garder le statut « candidature en préparation » et ne pas présenter SignPath comme un sponsor existant.

## Sources vérifiées le 23 octobre 2026

- [Conditions SignPath Foundation](https://signpath.org/terms.html)
- [Formulaire de candidature](https://signpath.org/apply.html)
- [Intégration GitHub et provenance des artifacts](https://docs.signpath.io/trusted-build-systems/github)
- [Configuration des artifacts et restrictions de métadonnées](https://docs.signpath.io/artifact-configuration/examples)
