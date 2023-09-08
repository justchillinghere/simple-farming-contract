//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Farming {
    using SafeERC20 for IERC20Metadata;

    struct User {
        uint256 stakedAmount;
        uint256 depositTime;
        bool claimed;
    }

    uint256 public constant HUNDRED_PERCENT = 10_000; // 100.00%

    address public owner;

    IERC20Metadata public stakingToken; // LP token

    IERC20Metadata public rewardToken; // token A or erc20

    uint256 public tokensLeft;

    uint256 public percentage;

    uint256 public startTime;

    uint256 public epochDuration;

    uint256 public amountOfEpochs;

    bool public initialized;

    mapping (address => User) public users;

    event Deposited(address addr, uint256 amount);
    event Withdraw(address addr, uint256 amount);
    event Claimed(address addr, uint256 amount);

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20Metadata(_stakingToken);
        rewardToken = IERC20Metadata(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

	modifier userDeposited () {
		require(users[msg.sender].stakedAmount > 0, "No token has been deposited by the account");
		_;
	}

	modifier farmingIsOver () {
		require(users[msg.sender].depositTime > 0, "No time has elapsed since the deposit");
		uint256 totalTerm = epochDuration * amountOfEpochs;
		uint256 currentDuration = block.timestamp - users[msg.sender].depositTime;
		require(currentDuration >= totalTerm, "Farming is not over yet");
		_;
	}

    function initialize(
        uint256 _totalAmount,
        uint256 _percentage, // 0 ~ 100.00% => 0 ~ 10000
        uint256 _epochDuration,
        uint256 _amountOfEpochs,
        uint256 _startTime
    ) external onlyOwner {
        require(!initialized, "Already initialized");
        initialized = true;
        tokensLeft = _totalAmount;
        percentage = _percentage;
        startTime = _startTime;
        amountOfEpochs = _amountOfEpochs;
        epochDuration = _epochDuration;

        rewardToken.safeTransferFrom(
            msg.sender,
            address(this),
            ((_totalAmount * _percentage * _amountOfEpochs) / HUNDRED_PERCENT)
        );
    }

    function deposit(uint256 _amount) external {
        require(startTime <= block.timestamp, "Farming is not up yet!");
        require(_amount <= tokensLeft, "Too many tokens contributed");
        require(users[msg.sender].stakedAmount == 0, "User can deposit only once");

        users[msg.sender] = User({
            stakedAmount: _amount,
            depositTime: block.timestamp,
            claimed: false
        });

        tokensLeft -= _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount);
    }

	function withdraw() userDeposited farmingIsOver public {

		uint256 amountToTransfer = users[msg.sender].stakedAmount;
		users[msg.sender].stakedAmount = 0;

		IERC20(stakingToken).approve(address(this), amountToTransfer);
		stakingToken.safeTransferFrom(address(this), msg.sender, amountToTransfer);
		emit Withdraw(msg.sender, amountToTransfer);
	}	

	function claimRewards() userDeposited farmingIsOver external {
		require(!users[msg.sender].claimed, "User already claimed");

		uint256 rewardToTransfer = (users[msg.sender].stakedAmount
			* percentage 
			* amountOfEpochs) 
			/ HUNDRED_PERCENT;
		
		require(rewardToTransfer > 0, "No reward to transfer");
		
		users[msg.sender].claimed = true;
		users[msg.sender].depositTime = 0;
		IERC20(rewardToken).approve(address(this), rewardToTransfer);
		rewardToken.safeTransferFrom(address(this), msg.sender, rewardToTransfer);
		emit Claimed(msg.sender, rewardToTransfer);
	}

}