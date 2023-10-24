pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { BaseTest } from "../BaseTest.t.sol";
import {PushFeePoolStaking} from "contracts/PushStaking/PushFeePoolStaking.sol";


contract BasePushFeePoolStaking is BaseTest{
    PushFeePoolStaking public feePoolStaking;
    /* ***************
       Initializing Set-Up for Push Contracts
     *************** */

    function setUp() public virtual override {
        BaseTest.setUp();

        feePoolStaking = new PushFeePoolStaking();

        // Initialize Push Fee Pool Contract
        feePoolStaking.initialize(
            actor.admin,
            address(core),
            address(pushToken),
            genesisEpoch,
            lastEpochInitialized,
            lastTotalStakeEpochInitialized,
            totalStakedAmount,
            previouslySetEpochRewards
        );

        vm.startPrank({ msgSender: actor.admin });
    }

}