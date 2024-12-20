// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EventRewardManager.t.sol";

contract WithdrawUnclaimedReward is EventRewardManagerTest {
    function testWithdrawUnclaimedRewards() public {
        //Create a token reward 
        rewardManager.createTokenReward(
            eventId,
            EventRewardManager.TokenType.USDC,
            address(usdcToken),
            rewardAmount
        );

        //Fast forward time
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = usdcToken.balanceOf(address(this));
        rewardManager.withdrawUnclaimedRewards(eventId);
        uint256 balanceAfter = usdcToken.balanceOf(address(this));

        assertEq(balanceAfter - balanceBefore, rewardAmount);
    }

    function testWithdrawBeforeTimeout() public {
        rewardManager.createTokenReward(
            eventId,
            EventRewardManager.TokenType.USDC,
            address(usdcToken),
            rewardAmount
        );

        vm.expectRevert("Withdrawal timeout not reached");
        rewardManager.withdrawUnclaimedRewards(eventId);
    }

    function testCancelAndReclaimReward() public {
        rewardManager.createTokenReward(
            eventId,
            EventRewardManager.TokenType.USDC,
            address(usdcToken),
            rewardAmount
        );

        // Fast forward time
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = usdcToken.balanceOf(address(this));
        rewardManager.cancelAndReclaimReward(eventId);
        uint256 balanceAfter = usdcToken.balanceOf(address(this));

        assertEq(balanceAfter - balanceBefore, rewardAmount);

        (,,,uint256 remainingReward,,bool isCancelled) = rewardManager.eventTokenRewards(eventId);
        assertEq(remainingReward, 0);
        assertTrue(isCancelled);
    }

    function testCancelAndReclaimRewardBeforeTimeout() public {
        rewardManager.createTokenReward(
            eventId,
            EventRewardManager.TokenType.USDC,
            address(usdcToken),
            rewardAmount
        );

        vm.expectRevert("Cancellation timeout not reached");
        rewardManager.cancelAndReclaimReward(eventId);
    }

    function testCancelAndReclaimRewardTwice() public {
        rewardManager.createTokenReward(
            eventId,
            EventRewardManager.TokenType.USDC,
            address(usdcToken),
            rewardAmount
        );

        // Fast forward time
        vm.warp(block.timestamp + 31 days);

        rewardManager.cancelAndReclaimReward(eventId);

        vm.expectRevert("Event reward already cancelled");
        rewardManager.cancelAndReclaimReward(eventId);
    }
}