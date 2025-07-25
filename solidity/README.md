never tested

# 🏛️ Cryptosystème Horizontal — Base Contracts

Ce dépôt contient les contrats de base d’un système crypto-organisationnel horizontal fondé sur :

- 🔐 une identité validée par la collectivité (Firme)
- ⛓️ une chaîne de valeur issue du **temps investi × ratio**
- 📜 des CGU collectivement gouvernées
- 🗳️ un système de scrutin transparent et révocable

---

## 📦 Contrats

### `User`

Classe représentant une personne dans le système.

```solidity
struct User {
    string name;
    address wallet;               // clé publique / portefeuille
    address[] voteKeys;           // clés de vote utilisées
    string[] contactMethods;      // min. 2 moyens de contact
    uint256 responseDelay;        // délai max d'accusé de réception
    string individualCGU;
    address[] associatedFirms;
    bool validatedByFirme;
}

struct Denier {
    address[] validators;         // min. 2 utilisateurs
    uint256 duration;             // en secondes
    uint8 ratio;                  // entre 1 et 6
    address firm;                 // projet ou structure associée
    uint256 timestamp;
}

struct Firme {
    string name;
    address[] users;
    mapping(address => uint8) ratios;  // ratios des utilisateurs
    uint256 revenue;
    string contractText;               // contrat d’objectif ou d’usage
    bytes32 authMethod;                // méthode d’authentification
    string collectiveCGU;
}

