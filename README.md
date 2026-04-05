# StoryCraft — Swift Web Application (CRUD)

## Description

StoryCraft est une application web développée en Swift avec le framework Hummingbird et une base de données SQLite.

L’objectif du projet est de concevoir une application CRUD complète permettant aux utilisateurs de créer, gérer et consulter des histoires en ligne.
Chaque utilisateur peut rédiger ses propres histoires, les organiser en chapitres et les publier pour les rendre accessibles aux autres utilisateurs.

Ce projet s’inscrit dans le cadre du cours de développement iOS (Université Paris 8, 2026) et démontre la mise en œuvre d’une architecture web complète en Swift.

---

## Fonctionnalités principales

* Authentification utilisateur (inscription / connexion)
* Création, modification et suppression d’histoires
* Gestion des chapitres (ajout, modification, suppression)
* Affichage des histoires publiées (exploration)
* Consultation détaillée d’une histoire
* Lecture continue des chapitres
* Gestion du profil utilisateur (pseudo, bio, avatar)

---

## Technologies utilisées

* Swift 6.2
* Hummingbird 2 (framework web)
* SQLite (via SQLite.swift)
* HTML/CSS généré côté serveur (Pico CSS)

---

## Structure du projet

.devcontainer/
devcontainer.json → configuration Codespaces

Sources/App/
main.swift → configuration du serveur et routes HTTP
Models.swift → structures de données (Utilisateur, Histoire, Chapitre, etc.)
Database.swift → gestion SQLite et opérations CRUD
Views.swift → génération des pages HTML

Package.swift → configuration du projet Swift
build.sh → script de compilation
run.sh → script de lancement du serveur

---

## Fonctionnement global

Le fonctionnement de l’application suit le schéma suivant :

Browser → requête HTTP
→ main.swift (router Hummingbird)
→ Database.swift (lecture / écriture SQLite)
→ Views.swift (génération HTML)
→ réponse HTTP → affichage dans le navigateur

---

## Routes principales

### GET

* `/` → page de connexion
* `/dashboard` → tableau de bord utilisateur
* `/histoires/publiees` → liste des histoires publiques
* `/histoires/{id}` → détail d’une histoire
* `/histoires/{id}/lecture` → lecture continue
* `/profil` → profil utilisateur

### POST

* `/register` → création de compte
* `/login` → connexion
* `/logout` → déconnexion
* `/histoires/ajouter` → création d’une histoire
* `/histoires/{id}/update` → modification d’une histoire
* `/histoires/{id}/supprimer` → suppression d’une histoire
* `/histoires/{id}/chapitres/ajouter` → ajout d’un chapitre
* `/chapitres/{id}/update` → modification d’un chapitre
* `/chapitres/{id}/supprimer` → suppression d’un chapitre

---

## Modèle de données principal

### Histoire

* id (clé primaire auto-incrémentée)
* titre
* genre
* resume
* statut (brouillon / publié)
* couverture (URL)

### Chapitre

* id
* histoireId
* numero
* titre
* contenu
* dateModification

---

## Concepts Swift utilisés

* `struct` pour les modèles de données
* Conformité aux protocoles `Codable` et `Sendable`
* `async/await` pour la gestion des requêtes serveur
* Closures dans les routes Hummingbird
* Gestion des erreurs avec `try` / `throws`
* Extensions (ex : `Connection: @unchecked Sendable`)

---

## Lancer le projet

Dans le terminal :

```bash
./build.sh
./run.sh
```

Puis ouvrir dans le navigateur :

http://localhost:8080

---

## Remarques

* L’application respecte les contraintes du projet : CRUD complet, routes HTTP, base SQLite et génération HTML côté serveur.
* L’interface utilisateur a été personnalisée pour améliorer l’expérience utilisateur au-delà du template initial.
* Le projet a été développé et testé intégralement dans GitHub Codespaces.

---
