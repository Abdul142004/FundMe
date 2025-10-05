//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");
    uint256 constant SEND_ETH = 0.1 ether;
    uint256 constant STARTING_BALANCE = 1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedIsAccurate() public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundme.fund{value: SEND_ETH}();
        uint256 amountFunded = fundme.addressToAmountFunded(USER);
        assertEq(amountFunded, SEND_ETH);
    }

    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_ETH}();

        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_ETH}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();
    }

    function testWithdrawWithASIngleFunder() public funded {
        //arrange
        uint256 ownerStartingBalance = fundme.getOwner().balance;
        uint256 fundMeStartingBalance = address(fundme).balance;
        //Act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            fundMeStartingBalance + ownerStartingBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_ETH);
            fundme.fund{value: SEND_ETH}();
        }

        uint256 ownerStartingBalance = fundme.getOwner().balance;
        uint256 fundMeStartingBalance = address(fundme).balance;

        //act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundme).balance, 0);
        assertEq(
            fundMeStartingBalance + ownerStartingBalance,
            fundme.getOwner().balance
        );
    }
}
