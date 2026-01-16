# TTGO T-Display – Flutter Mobile Application

Cette application mobile développée en **Flutter** permet d’interagir avec un capteur **TTGO T-Display (ESP32)** exposant une **API RESTful**.  
Elle offre une interface simple et intuitive pour **visualiser les données des capteurs**, **contrôler une LED**, **configurer un mode automatique par seuils**, et **analyser l’usage et l’historique via Firebase Firestore**.

L’application est conçue dans un objectif pédagogique et de supervision IoT.

---

## Fonctionnalités principales

### 🔹 Visualisation des capteurs
- Affichage de la **température (°C)** et de la **luminosité (raw)** en temps réel
- Indication d’état interprété :
  - Température : `COLD / NORMAL / HOT`
  - Luminosité : `DARK / BRIGHT`
- Rafraîchissement manuel et automatique des données

---

### 🔹 Contrôle de la LED
- Allumage de la LED (ON)
- Extinction de la LED (OFF)
- Changement d’état (TOGGLE)
- Indication visuelle de l’état actuel de la LED

---

### 🔹 Mode automatique (AUTO)
- Activation et désactivation du mode automatique
- Choix du capteur déclencheur (lumière ou température)
- Réglage du seuil via un slider
- Visualisation de l’état courant (AUTO actif ou non, seuils appliqués)

---

### 🔹 Affichage détaillé des capteurs
- Vue **texte** : valeurs, GPIO, type et unité des capteurs
- Vue **JSON** : affichage brut des réponses API (`/api/values`, `/api/sensors`)
- Outil utile pour le débogage et la compréhension de l’API

---

### 🔹 Graphiques et historique
- Graphiques de température et de luminosité
- Données issues de **Firebase Firestore**
- Visualisation de l’évolution dans le temps
- Indication des statuts directement sur les courbes

---

### 🔹 Statistiques et débogage
- Analyse de l’usage :
  - LED ON / OFF / TOGGLE
  - AUTO ON / OFF
  - Erreurs éventuelles
- Historique des derniers événements
- Affichage de la dernière localisation connue du device
- Données calculées à partir des événements Firestore existants

---

## API REST utilisée (ESP32)

L’application communique avec le TTGO T-Display via les routes suivantes :

### 🔸 Lecture des données
- `GET /api/values`  
  → valeurs des capteurs, états, seuils
- `GET /api/sensors`  
  → informations sur les capteurs (type, GPIO, unité)

### 🔸 Contrôle LED
- `POST /api/led/on`
- `POST /api/led/off`
- `POST /api/led/toggle`

### 🔸 Mode automatique
- `POST /api/auto/light`
- `POST /api/auto/temp`
- `POST /api/auto/disable`

Les échanges sont réalisés en **JSON via HTTP** sur le réseau local.

---

## Firebase Firestore

Firebase Firestore est utilisé pour :
- stocker l’historique des mesures des capteurs
- enregistrer les événements utilisateur (LED, AUTO, erreurs)
- permettre l’affichage des graphiques et statistiques
- faciliter le débogage post-exécution

Aucun backend supplémentaire n’est requis.

---

## Installation et exécution

### Prérequis
- Flutter SDK installé
- Un smartphone Android ou un émulateur
- Un TTGO T-Display connecté au même réseau Wi-Fi
- Un projet Firebase configuré

### Étapes

```bash
git clone https://github.com/your-username/ttgo-flutter-app.git
cd ttgo-flutter-app
flutter pub get
flutter run
