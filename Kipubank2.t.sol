// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/KipuBank.sol";

contract KipuBankTest is Test {
    KipuBank private kipu;
    address private usuario = address(1);

    uint256 private constant BANK_CAP = 10 ether;
    uint256 private constant LIMIT_PER_WITHDRAWAL = 1 ether;

    function setUp() public {
        kipu = new KipuBank(BANK_CAP, LIMIT_PER_WITHDRAWAL);

        // Registrar e habilitar o usuário
        vm.prank(address(this)); // deployer é o owner
        kipu.registrarUsuario(usuario);

        //vm.prank(address(this));
        //kipu.habilitarUsuario(usuario);

        vm.deal(usuario, 10 ether); // adiciona saldo ao usuário
    }

    function testDepositoBemSucedido() public {
        vm.prank(usuario);
        kipu.deposito{value: 1 ether}();

        vm.prank(usuario);
        uint256 saldo = kipu.consultarMeuSaldo();
        assertEq(saldo, 1 ether);
    }

    function testSaqueDentroDoLimite() public {
        vm.prank(usuario);
        kipu.deposito{value: 1 ether}();

        vm.prank(usuario);
        kipu.saque(0.5 ether);

        vm.prank(usuario);
        uint256 saldo = kipu.consultarMeuSaldo();
        assertEq(saldo, 0.5 ether);
    }

    function testDepositoFalhaLimiteExcedido() public {
        vm.deal(usuario, 20 ether); // mais do que o cap
        vm.prank(usuario);
        vm.expectRevert(KipuBank.KipuBank_LimiteExcedido.selector);
        kipu.deposito{value: 11 ether}();
    }

    function testSaqueFalhaSaldoInsuficiente() public {
        vm.prank(usuario);
        kipu.deposito{value: 0.5 ether}();

        vm.prank(usuario);
        vm.expectRevert(KipuBank.KipuBank_SaldoInsuficiente.selector);
        kipu.saque(1 ether);
    }
}
