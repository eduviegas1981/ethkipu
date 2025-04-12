// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/KipuBank.sol";

contract KipuBankAccessTest is Test {
    KipuBank private kipu;
    address private usuarioAutorizado = address(1);
    address private atacante = address(2);

    function setUp() public {
        kipu = new KipuBank(10 ether, 1 ether);

        // Registrar o usuário 1
        vm.prank(address(this));
        kipu.registrarUsuario(usuarioAutorizado);

        vm.deal(usuarioAutorizado, 5 ether);
        vm.deal(atacante, 5 ether);
    }

    function testRejeitaDepositoNaoAutorizado() public {
        vm.prank(atacante);
        vm.expectRevert(KipuBank.KipuBank_NaoAutorizado.selector);
        kipu.deposito{value: 1 ether}();
    }

    function testRejeitaSaqueNaoAutorizado() public {
        vm.prank(atacante);
        vm.expectRevert(KipuBank.KipuBank_NaoAutorizado.selector);
        kipu.saque(0.5 ether);
    }
}
