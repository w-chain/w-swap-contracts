pragma solidity 0.6.6;

import "forge-std/Script.sol";

interface Factory {
    function setFeeTo(address) external;
}

contract Deploy is Script {
    function run() external {
        address DEPLOYER = vm.envAddress("DEPLOYER_ADDRESS");
        address FEE_TO = vm.envAddress("FEE_TO_ADDRESS");
        address WETH = vm.envAddress("WETH_ADDRESS");

        vm.startBroadcast();
        address factory = deployCode("WSwapV2Factory.sol:WSwapV2Factory", abi.encode(DEPLOYER));
        console.log("Factory deployed at:", factory);
        Factory(factory).setFeeTo(FEE_TO);

        address router = deployCode("WSwapV2Router02.sol:WSwapV2Router02", abi.encode(factory, WETH));
        console.log("Router deployed at:", router);
        vm.stopBroadcast();
    }
}