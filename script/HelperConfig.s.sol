// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../src/constants/CodeConstants.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint256 lotteryEntranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_FUJI_CHAIN_ID] = getFujiEthConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        // networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getFujiEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subscriptionId: 104323973274119965933394290503121927888729925478496282869728367109124726179162, // If left as 0, our scripts will create one!
                gasLane: 0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887,
                automationUpdateInterval: 30, // 30 seconds
                lotteryEntranceFee: 0.01 ether,
                callbackGasLimit: 500000, // 500,000 gas
                vrfCoordinatorV2_5: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE, //FuJi Testnet
                link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
                account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
            });
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subscriptionId: 2881574978804262288018695338899595037363175439649635035677948032680127688490, // If left as 0, our scripts will create one!
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                automationUpdateInterval: 30, // 30 seconds
                lotteryEntranceFee: 0.01 ether,
                callbackGasLimit: 500000, // 500,000 gas
                vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Checks to see if we set an active network config
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();

        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UINT_LINK
            );
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30, // 30 seconds
            lotteryEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });

        return localNetworkConfig;
    }
}
