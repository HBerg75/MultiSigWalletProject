// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract TargetContract {
    uint256 public data;

    function getData() external {
        data = 42; // Exemple de logique
    }
}

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address signer1 = address(0x1);
    address signer2 = address(0x2);
    address signer3 = address(0x3);
    address nonSigner = address(0x4);

    // setUp() est exécutée avant chaque test pour initialiser le contrat avec 3 signataires.
    function setUp() public {
        address[] memory signers = new address[](3);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;

        wallet = new MultiSigWallet(signers);
    }

    // Test 1 : Vérifie que les signataires sont correctement initialisés.
    function testSignersInitialization() public {
        address[] memory signers = wallet.getSigners();

        assertEq(signers[0], signer1, "Signer 1 incorrect");
        assertEq(signers[1], signer2, "Signer 2 incorrect");
        assertEq(signers[2], signer3, "Signer 3 incorrect");
        assertTrue(wallet.isSigner(signer1), "Signer 1 non reconnu");
        assertTrue(wallet.isSigner(signer2), "Signer 2 non reconnu");
        assertTrue(wallet.isSigner(signer3), "Signer 3 non reconnu");
        assertFalse(wallet.isSigner(nonSigner), "Non-signer reconnu comme signer");
    }

    // Test 2 : Vérifie qu'une transaction peut être soumise et correctement enregistrée.
    function testSubmitTransaction() public {
    vm.prank(signer1); // Simule signer1 comme appelant
    wallet.submitTransaction(address(0x5), 1 ether, "");

    (address to, uint256 value, , bool executed, uint256 approvals) = wallet.transactions(0);

    assertEq(to, address(0x5), "Incorrect recipient");
    assertEq(value, 1 ether, "Incorrect value");
    assertFalse(executed, "Transaction marked as executed");
    assertEq(approvals, 0, "Initial approvals count incorrect");
}


    // Test 3 : Vérifie que les approbations fonctionnent et permettent d'exécuter une transaction.
    function testApproveAndExecuteTransaction() public {
    // Déploie un contrat cible
    TargetContract target = new TargetContract();

    vm.deal(address(wallet), 1 ether); // Approvisionne le contrat avec 1 Ether

    address recipient = address(target); // Utilise l'adresse du contrat cible
    vm.prank(signer1); // Simule signer1 comme soumettant
    wallet.submitTransaction(recipient, 0, ""); // Pas besoin de transférer de valeur ici

    vm.prank(signer1); // Simule signer1 comme approuvant
    wallet.approveTransaction(0);

    vm.prank(signer2); // Simule signer2 comme approuvant
    wallet.approveTransaction(0);

    // Exécute la transaction
    vm.prank(signer1); // Simule signer1 comme exécutant
    wallet.executeTransaction(0);

    // Vérifie que la fonction `getData()` a été appelée
    assertEq(target.data(), 42, "getData() was not called correctly");
}






    // Test 4 : Vérifie qu'un non-signataire ne peut pas approuver une transaction.
    function testNonSignerCannotApprove() public {
    vm.prank(signer1); // Simule signer1 comme soumettant
    wallet.submitTransaction(address(0x5), 1 ether, "");

    vm.prank(nonSigner); // Simule nonSigner comme approuvant
    vm.expectRevert("Not a signer");
    wallet.approveTransaction(0);
}


    // Test 5 : Vérifie qu'un signataire peut être retiré et n'est plus reconnu comme signataire.
    function testRemoveSigner() public {
    vm.prank(signer1); // Simule signer1 comme ajoutant un signataire
    wallet.addSigner(address(0x6)); // Ajoute un nouveau signataire

    vm.prank(signer1); // Simule signer1 comme appelant
    wallet.removeSigner(signer3); // Retire signer3

    assertFalse(wallet.isSigner(signer3), "Signer3 still recognized as signer");
    assertTrue(wallet.isSigner(address(0x6)), "New signer not recognized");
    }

    function testContractFunding() public {
    vm.deal(address(wallet), 1 ether); // Approvisionne le contrat

    uint256 contractBalance = address(wallet).balance;
    assertEq(contractBalance, 1 ether, "Contract balance incorrect");
    }

     // Test 6 : Vérifie qu'un signataire non autorisé ne peut pas soumettre une transaction.
    function testNonSignerCannotSubmitTransaction() public {
        vm.prank(nonSigner); // Simule un non-signataire
        vm.expectRevert("Not a signer");
        wallet.submitTransaction(address(0x5), 1 ether, "");
    }

    // Test 7 : Vérifie qu'un signataire ne peut pas être ajouté deux fois.
    function testAddExistingSigner() public {
        vm.prank(signer1); // Simule signer1 comme appelant
        vm.expectRevert("Already a signer");
        wallet.addSigner(signer2); // Tente d'ajouter signer2 qui est déjà un signataire
    }

    // Test 8 : Vérifie qu'une transaction sans approbations suffisantes échoue.
    function testExecuteTransactionWithoutApprovals() public {
        vm.prank(signer1); // Simule signer1 comme appelant
        wallet.submitTransaction(address(0x5), 1 ether, "");

        vm.expectRevert("Not enough approvals");
        vm.prank(signer1);
        wallet.executeTransaction(0); // Tente d'exécuter sans approbations suffisantes
    }

    // Test 9 : Vérifie qu'un signataire inexistant ne peut pas être supprimé.
    function testRemoveNonExistingSigner() public {
        vm.prank(signer1);
        vm.expectRevert("Not a signer");
        wallet.removeSigner(nonSigner); // Tente de supprimer une adresse qui n'est pas un signataire
    }

    // Test 10 : Vérifie qu'une transaction avec une valeur nulle peut être soumise.
    function testSubmitTransactionWithZeroValue() public {
        vm.prank(signer1);
        wallet.submitTransaction(address(0x5), 0, "");
        (address to, uint256 value, , , ) = wallet.transactions(0);
        assertEq(to, address(0x5), "Incorrect recipient");
        assertEq(value, 0, "Incorrect value");
    }

    // Test 11 : Vérifie qu'une approbation déjà révoquée ne peut pas être révoquée à nouveau.
    function testRevokeApprovalAlreadyRevoked() public {
        vm.prank(signer1);
        wallet.submitTransaction(address(0x5), 1 ether, "");

        vm.prank(signer1);
        wallet.approveTransaction(0); // Approuve la transaction

        vm.prank(signer1);
        wallet.revokeApproval(0); // Révoque l'approbation

        vm.prank(signer1);
        vm.expectRevert("Transaction not approved");
        wallet.revokeApproval(0); // Tente de révoquer à nouveau
    }

    

}