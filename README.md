# Projet Capstone - Application de Gestion des Étudiants sur AWS

## 🎯 Scénario

L'Université Exemple se prépare à la nouvelle année scolaire. Le service des admissions a reçu des plaintes selon lesquelles son application web pour les dossiers des étudiants est lente ou n'est pas disponible pendant la période de pointe des admissions en raison du nombre élevé de demandes de renseignements.

En tant qu'ingénieur cloud, vous devez créer une preuve de concept (POC) pour héberger l'application web dans le Cloud AWS. L'objectif est de concevoir et mettre en œuvre une nouvelle architecture d'hébergement qui améliorera l'expérience des utilisateurs de l'application web.

**Application** : Système de gestion des étudiants permettant de visualiser, ajouter, modifier et supprimer des enregistrements d'étudiants.

**Stack technique** : Node.js + Express + MySQL

## 📋 Exigences de la solution

La solution doit répondre aux exigences suivantes :

- **Fonctionnelle** : La solution répond aux exigences fonctionnelles, telles que la possibilité de consulter, d'ajouter, de supprimer ou de modifier les dossiers des étudiants, sans latence perceptible.
- **À charge équilibrée** : La solution peut équilibrer correctement le trafic des utilisateurs afin d'éviter la surcharge ou la sous-utilisation des ressources.
- **Pouvant être mise à l'échelle** : La solution est conçue pour être mise à l'échelle pour répondre aux exigences de l'application.
- **Hautement disponible** : La solution est conçue pour limiter les temps d'arrêt en cas d'indisponibilité d'un serveur web.
- **Sécurisée** :
  - La base de données est sécurisée et il est impossible d'y accéder directement à partir de réseaux publics.
  - Les serveurs web et la base de données ne sont accessibles que par les ports appropriés.
  - L'application web est accessible via Internet.
  - Les identifiants de la base de données ne sont pas codés en dur dans l'application web.
- **Coûts optimisés** : La solution est conçue pour maintenir les coûts à un niveau bas.
- **Très performante** : Les opérations de routine sont effectuées sans latence perceptible dans des conditions de charge normale, variable et de pointe.

## 🚀 Approche par phases

Le développement de la solution est réalisé en 6 phases progressives, permettant de garantir que les fonctionnalités de base fonctionnent avant que l'architecture ne devienne plus complexe.

---


## AMELIORATION PHASE 7

-Création de la phase6 depuis une pipeline avec Terraform
-Création d'un becket s3 de state terraform
-Création d'un service d'authentification Keycloak, accèes via DNS LB
---

