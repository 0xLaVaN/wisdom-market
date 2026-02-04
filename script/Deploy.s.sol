// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/WisdomMarket.sol";

contract DeployWisdomMarket is Script {
    // $LAVAN on Base (Moltlaunch/Flaunch deploy)
    address constant LAVAN_TOKEN = 0x5d37d625565521f836b95b11F3fa7494e699D151;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        WisdomMarket market = new WisdomMarket(LAVAN_TOKEN);
        
        console.log("WisdomMarket deployed at:", address(market));
        console.log("Staking token ($LAVAN):", LAVAN_TOKEN);
        
        vm.stopBroadcast();
    }
}
