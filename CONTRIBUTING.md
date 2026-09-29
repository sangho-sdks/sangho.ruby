# Contribuer au SDK Sangho

Merci de l'intérêt pour ce SDK ! Voici comment contribuer.

---

## Workflow

1. **Fork** le repo et crée une branche depuis `main` :

   ```bash
   git checkout -b feat/ma-fonctionnalite
   ```

2. **Code** en suivant les conventions du projet (voir ci-dessous).

3. **Tests** — assure-toi que tous les tests passent avant de soumettre.

4. **Commit** en suivant le format [Conventional Commits](https://www.conventionalcommits.org/fr/) :

   ```
   feat: ajouter support de la ressource X
   fix: corriger le mapping d'erreur 403
   chore: mettre à jour les dépendances
   docs: améliorer les exemples du README
   ```

5. **Pull Request** vers `main` en utilisant le template fourni.

---

## Conventions de nommage

| Langage | Ressources | Payloads create | Payloads update |
|---------|------------|-----------------|-----------------|
| JS/TS   | camelCase  | `CreatePayloads`| `Payloads`      |
| Python  | snake_case | `CreatePayloads`| `Payloads`      |
| PHP     | camelCase  | `array`         | `array`         |
| Ruby    | snake_case | `Hash`          | `Hash`          |
| Java    | camelCase  | `CreatePayloads`| `Payloads`      |

---

## Versioning

Ce SDK suit le **Semantic Versioning** :

- `MAJOR` — breaking change dans l'API publique
- `MINOR` — nouvelle fonctionnalité rétrocompatible
- `PATCH` — correction de bug rétrocompatible

Tous les SDKs sont versionnés de façon synchronisée (ex: v0.1.4 = même version partout).

---

## Reporting de bugs

Utilise les **Issues GitHub** avec le template approprié :

- 🐛 Bug report
- 💡 Feature request

---

## Code de conduite

Sois respectueux et constructif. Les contributions agressives ou hors-sujet seront ignorées.
