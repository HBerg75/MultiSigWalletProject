# MultiSigWallet

Ce projet implémente un portefeuille multisignature (MultiSig Wallet) développé en Solidity. Il permet à plusieurs signataires de gérer des transactions ensemble, avec des exigences de validation prédéfinies avant l'exécution d'une transaction.

---

## Fonctionnalités principales

- **Déploiement du portefeuille** : Initialisé avec au moins trois adresses de signataires.
- **Soumission de transactions** : Les signataires peuvent proposer des transactions.
- **Validation des transactions** : Les transactions doivent être approuvées par au moins deux signataires avant leur exécution.
- **Exécution des transactions** : Une fois approuvée, une transaction peut être exécutée par un des signataires.
- **Ajout et suppression de signataires** : Les signataires peuvent être ajoutés ou supprimés tout en respectant un minimum de trois signataires.
- **Historique des transactions** : Toutes les transactions sont enregistrées pour un suivi transparent.

---

## Structure du projet

### **Fichiers principaux**

1. **`src/MultiSigWallet.sol`** : Le contrat principal implémentant la logique du portefeuille multisignature.
2. **`test/MultiSigWalletTest.t.sol`** : Les tests unitaires pour valider les fonctionnalités du contrat.
3. **`TargetContract.sol`** : Contrat cible utilisé pour simuler l'exécution des transactions.

---

## Instructions pour le déploiement et les tests

### **Prérequis**

- [Foundry](https://book.getfoundry.sh/) installé sur votre machine.
- Node.js pour l'installation des dépendances (si nécessaire).

### **Étapes pour exécuter le projet**

1. **Cloner le projet** :
   ```bash
   git clone https://github.com/HBerg75/MultiSigWalletProject.git
   cd MultiSigWalletProject
   ```

2. **Installer les dépendances Foundry** :
   ```bash
   forge install
   ```

3. **Exécuter les tests** :
   ```bash
   forge test
   ```

4. **Vérifier la couverture des tests** :
   ```bash
   forge coverage
   ```

---

## Détails des fonctionnalités

### **Constructeur**

```solidity
constructor(address[] memory initialSigners)
```
- Initialise le portefeuille avec une liste d'adresses de signataires.
- Exige au moins trois signataires uniques.

### **Soumission d'une transaction**

```solidity
function submitTransaction(address to, uint256 value, bytes memory data) external onlySigner
```
- Permet à un signataire de proposer une transaction en spécifiant l'adresse destinataire, la valeur (ETH) et les données supplémentaires.

### **Validation d'une transaction**

```solidity
function approveTransaction(uint256 txId) external onlySigner
```
- Un signataire approuve une transaction en cours.
- Nécessite que le signataire n'ait pas déjà approuvé cette transaction.

### **Révocation d'une validation**

```solidity
function revokeApproval(uint256 txId) external onlySigner
```
- Permet à un signataire de retirer son approbation avant l'exécution de la transaction.

### **Exécution d'une transaction**

```solidity
function executeTransaction(uint256 txId) external onlySigner
```
- Exécute une transaction approuvée par au moins deux signataires.
- Transfère les fonds et exécute les données fournies dans la transaction.

### **Gestion des signataires**

- **Ajouter un signataire** :
  ```solidity
  function addSigner(address newSigner) external onlySigner
  ```
  Ajoute un nouveau signataire au portefeuille.

- **Supprimer un signataire** :
  ```solidity
  function removeSigner(address signer) external onlySigner
  ```
  Supprime un signataire, en assurant qu'il reste au moins trois signataires.

---

## Tests

Les tests unitaires sont écrits avec Foundry et couvrent les scénarios suivants :

1. Initialisation des signataires.
2. Soumission, validation, révocation et exécution de transactions.
3. Gestion des signataires (ajout/suppression).
4. Vérification des restrictions d'accès pour les non-signataires.

Pour exécuter les tests :
```bash
forge test
```

Pour afficher la couverture des tests :
```bash
forge coverage
```

---

## Événements

Le contrat utilise plusieurs événements pour assurer la traçabilité :

- **`TransactionSubmitted`** : Déclenché lorsqu'une transaction est soumise.
- **`TransactionApproved`** : Déclenché lorsqu'une transaction est approuvée.
- **`TransactionRevoked`** : Déclenché lorsqu'une approbation est révoquée.
- **`TransactionExecuted`** : Déclenché lorsqu'une transaction est exécutée.
- **`SignerAdded`** : Déclenché lorsqu'un signataire est ajouté.
- **`SignerRemoved`** : Déclenché lorsqu'un signataire est supprimé.

---

## Auteurs

- **[Hberg75]** : Développeur du projet.

---

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.
