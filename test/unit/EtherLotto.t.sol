// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DeployEtherLotto} from "../../script/DeployEtherLotto.s.sol";
import {EtherLotto} from "../../src/EtherLotto.sol";
// import {HelperConfig} from "../../script/config/HelperConfig.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract EtherLottoTest is Test {
    EtherLotto public etherLotto;
    HelperConfig public helperConfig;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 lotteryEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    // LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    event LotteryEntered(address indexed player);
    event WinnerPicked(address indexed player);

    function setUp() external {
        DeployEtherLotto deployer = new DeployEtherLotto();
        (etherLotto, helperConfig) = deployer.deployContracts();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        lotteryEntranceFee = config.lotteryEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        // link = LinkToken(config.link);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(
            etherLotto.getEtherLottoState() == EtherLotto.EtherLottoState.OPEN
        );
    }

    function testLotteryRevertsWHenYouDontPayEnough() public {
        vm.prank(PLAYER);

        vm.expectRevert(EtherLotto.EtherLotto__sendMoreToEnterLottery.selector);
        etherLotto.enterLottery();
    }

    function testLotteryRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);

        etherLotto.enterLottery{value: lotteryEntranceFee}();

        address playerRecorded = etherLotto.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(etherLotto));
        emit LotteryEntered(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
    }

    function testDontAllowPlayersToEnterWhileLotteryIsCalculating() public {
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        etherLotto.performUpkeep("");

        vm.expectRevert(EtherLotto.EtherLotto__LotteryNotOpen.selector);
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = etherLotto.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfLotteryIsntOpen() public {
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        etherLotto.performUpkeep("");
        EtherLotto.EtherLottoState etherLottoState = etherLotto
            .getEtherLottoState();

        (bool upkeepNeeded, ) = etherLotto.checkUpkeep("");

        // assert(etherLotto == EtherLotto.EtherLottoState.CALCULATING);
        assert(upkeepNeeded == false);
    }
}
