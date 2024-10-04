// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {DeployEtherLotto} from "../../script/DeployEtherLotto.s.sol";
import {EtherLotto} from "../../src/EtherLotto.sol";
// import {HelperConfig} from "../../script/config/HelperConfig.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        etherLotto.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        EtherLotto.EtherLottoState lState = etherLotto.getEtherLottoState();

        vm.expectRevert(
            abi.encodeWithSelector(
                EtherLotto.EtherLotto__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                lState
            )
        );
        etherLotto.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        etherLotto.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        EtherLotto.EtherLottoState etherLottoState = etherLotto
            .getEtherLottoState();
        // requestId = etherLotto.getLastRequestId();
        assert(uint256(requestId) > 0);
        assert(uint256(etherLottoState) == 1); // 0 = open, 1 = calculating
    }

    modifier lotteryEntered() {
        vm.prank(PLAYER);
        etherLotto.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
        public
        lotteryEntered
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            0,
            address(etherLotto)
        );

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            1,
            address(etherLotto)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        lotteryEntered
        skipFork
    {
        address expectedWinner = address(1);

        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 10 ether); // deal 1 eth to the player
            etherLotto.enterLottery{value: lotteryEntranceFee}();
        }

        uint256 startingTimeStamp = etherLotto.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        vm.recordLogs();
        etherLotto.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console2.logBytes32(entries[1].topics[1]);
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            uint256(requestId),
            address(etherLotto)
        );

        address recentWinner = etherLotto.getRecentWinner();

        EtherLotto.EtherLottoState etherLottoState = etherLotto
            .getEtherLottoState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = etherLotto.getLastTimeStamp();
        uint256 prize = lotteryEntranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        // assert(uint256(etherLotto) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
