# CYJE - Les Toiles de Minuit BC06

Test technique pour la mission Les Toiles de Minuit (BC06). Ce projet est une API REST développée avec Symfony, accompagnée d'une application frontend (Flutter) pour la gestion d'événements.

---

## 📂 Architecture du projet

```
CYJE-Les_Toiles_de_Minuit_BC06/
├── API_Backend_Symfony/    # Backend Symfony
│   ├── config/
│   │   ├── packages/
│   │   │   ├── nelmio_cors.yaml   # Configuration CORS via NelmioCorsBundle
│   │   │   ├── security.yaml   # Configuration des acces aux routes
│   │   │   └── ...
│   │   ├── routes.yaml            # Routes de l'API
│   │   └── services.yaml
│   ├── src/
│   │   ├── Controller/            # Contrôleurs API (EventController, RegistrationController...)
│   │   ├── Entity/                # Entités Doctrine (Event, User, EventRegistration...)
│   │   ├── Repository/
│   │   └── DataFixtures/              # Fixtures Doctrine pour population initiale
│   ├── public/
│   │   ├── index.php
│   │   ├── Bundles/                # Swagger disponible à l'adresse : http://localhost/api/doc
│   │   └── EventImage/             # Dossier des images uploadées
│   ├── .env                        # Variables d'environnement
│   ├── composer.json
│   └── symfony.lock
├──frontend/                # Application Flutter
│   ├── lib/
│   │   ├── models/
│   │   ├── pages/                  # pages frontend de chaque utilisateur
│   │   ├── services/               #    services d'authentification et d'API
│   │   ├── widgets/                # utilisation reguliere de code, pour eviter de dupliquer
│   │   └── main.dart
│   └── pubspec.yaml
├──docker/ 
│   ├── db/                         # init db pour mettre le schema de base au lancement du docker
│   ├── nginx/                      # configutaion du serveur nginx
│   └── php/                        # dockerfile pour le php afin d'installer toutes les dependances au lancement du docker
└──docker-compose.yml

```

---

## 🚀 Lancement rapide avec Docker

### 1️⃣  Démarrage

```bash
docker-compose up --build -d
```

### 2️⃣  Initialisation de la base et fixtures

```bash
docker-compose exec php php bin/console doctrine:fixtures:load

# alternative 
docker-compose exec php bash
php bin/console doctrine:fixtures:load
```

### 3️⃣  Lancer le frontend Flutter (en local, hors Docker)

```bash
cd Frontend_Flutter
flutter pub get
flutter run -d chrome
```

# ✅ Stack

* Symfony API sous Docker
* Base initialisée avec `init.db.sql` + fixtures Symfony
* Gestion CORS avec NelmioCorsBundle
* Swagger (NelmioApiDocBundle) pour la documentation à `http://localhost/api/doc`
* Authentification JWT pour sécuriser les routes
* Trois rôles utilisateurs disponibles : `ROLE_USER`, `ROLE_ORGANIZER`, `ROLE_ADMIN`
* Accès API sécurisé par rôle

---

## 🔐 Sécurité et CORS

* **JWT** : Utilisé pour l'authentification et l'autorisation (login, routes protégées).
* **NelmioCorsBundle** : Permet de gérer les politiques CORS. Fichier `config/packages/nelmio_cors.yaml` :

  ```yaml
  nelmio_cors:
    defaults:
        allow_credentials: false
        allow_origin: ['http://localhost:4200', 'http://localhost:8080', 'http://10.0.2.2:8080']
        allow_headers: ['Content-Type', 'Authorization']
        allow_methods: ['GET', 'OPTIONS', 'POST', 'PUT', 'DELETE']
        max_age: 3600
    paths:
        '^/api/':
            allow_origin: ['*']
            allow_headers: ['Content-Type', 'Authorization']
            allow_methods: ['GET', 'OPTIONS', 'POST', 'PUT', 'DELETE']
            max_age: 3600
        '^/EventImage/':
            allow_origin: [ '*' ]
            allow_headers: [ 'Content-Type' ]
            allow_methods: [ 'GET' , 'OPTIONS']
  ```

---

## 📑 Routes principales

Toutes les routes principales de l’API REST sont documentées dans Swagger une fois le docker lancé à l’adresse : http://localhost/api/doc

---

## 🔑 Credentials par défaut

| Email                                                     | Rôle            | Mot de passe |
| --------------------------------------------------------- | --------------- | ------------ |
| **[user@example.com](mailto:user@example.com)**           | ROLE\_USER      | `user`       |
| **[organizer@example.com](mailto:organizer@example.com)** | ROLE\_ORGANIZER | `organizer`  |
| **[admin@example.com](mailto:admin@example.com)**         | ROLE\_ADMIN     | `admin`      |

---

## 🗂️ Données de test

* 3 utilisateurs créés (user, organizer, admin)
* 3 événements créés :

    * 2 en `published`
    * 1 en `draft`
    * L'utilisateur `user@example.com` est inscrit à 1 événement published
  
---

## État du projet

Ce projet est actuellement en cours de développement. De nombreuses fonctionnalités importantes sont encore en cours d'implémentation et seront ajoutées dans les prochaines versions. Nous travaillons activement à l'amélioration de l'application pour vous offrir une expérience complète et robuste.

### Fonctionnalités à venir

- Optimisation des performances et de l’ergonomie
- Amélioration de la gestion des utilisateurs et des événements
- Support avancé des inscriptions et paiements

### Bugs connus

Certaines anomalies et bugs subsistent dans cette version. Nous sommes conscients de ces problèmes et nous nous engageons à les corriger dans les mises à jour prochaines.

---

N’hésitez pas à contribuer ou à nous faire part de vos retours pour nous aider à faire évoluer ce projet !


© 2025 Les Toiles de Minuit BC06
