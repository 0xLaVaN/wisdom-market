// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/WisdomMarket.sol";

contract DeployWisdomMarket is Script {
    // $LAVA on Base (Clanker deploy)
    address constant LAVA_TOKEN = 0xbCd8294cCB57baEAa76168E315D4AD56B2439B07;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        WisdomMarket market = new WisdomMarket(LAVA_TOKEN);
        
        console.log("WisdomMarket deployed at:", address(market));
        console.log("Staking token ($LAVA):", LAVA_TOKEN);
        
        vm.stopBroadcast();
    }
}
