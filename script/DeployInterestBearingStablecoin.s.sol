// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/InterestBearingStablecoin.sol";

contract DeployInterestBearingStablecoin is Script {
    function run() external {
        // Load deployment parameters
        address usdc = vm.envAddress("USDC_ADDRESS");    // Set this in your environment
        address steth = vm.envAddress("STETH_ADDRESS");  // Set this in your environment
        address oracle = vm.envAddress("ORACLE_ADDRESS"); // Set this in your environment
        address dex = vm.envAddress("DEX_ADDRESS");      // Set this in your environment

        // Begin deployment
        vm.startBroadcast();

        // Deploy the contract
        InterestBearingStablecoin stablecoin = new InterestBearingStablecoin(
            usdc,
            steth,
            oracle,
            dex
        );

        vm.stopBroadcast();

        console.log("InterestBearingStablecoin deployed at:", address(stablecoin));
    }
}
