//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFarming {
    struct User {
        uint256 stakedAmount;
        uint256 depositTime;
        bool claimed;
    }

    function initialize(
        uint256 _totalAmount,
        uint256 _percentage,
        uint256 _epochDuration,
        uint256 _amountOfEpochs,
        uint256 _startTime
    ) external;

    function deposit(uint256 _amount) external;

    function withdraw() external;

    function claimRewards() external;
}

