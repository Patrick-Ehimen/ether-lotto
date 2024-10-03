// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EtherLotto} from "../src/EtherLotto.sol";
// import {HelperConfig} from "./config/HelperConfig.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployEtherLotto is Script {
    function run() public {}

    function deployContracts() public returns (EtherLotto, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (
                config.subscriptionId,
                config.vrfCoordinatorV2_5
            ) = createSubscription.createSubscription(
                config.vrfCoordinatorV2_5
                // config.account
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5,
                config.subscriptionId,
                config.link
                // config.account
            );

            // helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast();
        EtherLotto etherLotto = new EtherLotto(
            config.lotteryEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(etherLotto),
            config.vrfCoordinatorV2_5,
            config.subscriptionId
            // config.account
        );

        return (etherLotto, helperConfig);
    }
}
