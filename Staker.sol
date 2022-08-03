// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline;
    uint256 public startStake;
    bool public openForWithdraw;

    event Stake(address indexed from, uint256 amount);
    event Withdraw(address, uint256);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        startStake = block.timestamp;
        deadline = startStake + 72 hours;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        //require(msg.value > 0, "Stake amount must be grater than 0");
        balances[msg.sender] += msg.value; // tracking the balance
        emit Stake(msg.sender, msg.value);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        uint256 currentTiimeStamp = block.timestamp;
        if (currentTiimeStamp >= deadline) {
            return 0;
        } else {
            return (deadline - currentTiimeStamp);
        }
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public payable notCompleted {
        // checking the deadline expired or not...
        require(timeLeft() == 0, "deadline is exceeded!");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
            //withdraw();
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public payable notCompleted {
        require(timeLeft() == 0, "deadline is exceeded1!!!!");
        require(
            openForWithdraw,
            "You can't withdraw now - balance is more than threshold."
        );
        uint256 withdrawBalance = balances[msg.sender];

        //payable(msg.sender).call{value: withdrawBalance};
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, withdrawBalance);
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "It's already completed!"
        );
        _;
    }
}
//!==========
