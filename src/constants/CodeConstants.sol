// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_FUJI_CHAIN_ID = 43113;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}