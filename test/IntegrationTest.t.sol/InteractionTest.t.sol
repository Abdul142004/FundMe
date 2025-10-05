//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");
    uint256 constant SEND_ETH = 0.1 ether;
    uint256 constant STARTING_BALANCE = 1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundme = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFund() public {
        FundFundMe fundFundMe = new FundFundMe();
        // vm.prank(USER);
        // vm.deal(USER, 1e18);
        fundFundMe.fundFundMe(address(fundme));

        // address funder = fundme.getFunder(0);
        // assertEq(funder, USER);
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundme));

        assertEq(address(fundme).balance, 0);
    }
}
