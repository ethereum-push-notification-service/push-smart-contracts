pragma solidity ^0.8.0;
import {BaseTest} from "../../../BaseTest.t.sol";
import {CoreTypes} from "../../../../contracts/libraries/DataTypes.sol";
import {SignatureVerifier} from "contracts/mocks/MockERC1271.sol";

import "forge-std/console.sol";

contract SubscribeBySig_Test is BaseTest {
    bytes constant _testChannelIdentity = bytes("test-channel-hello-world");
    event Subscribe(address indexed channel, address indexed user);
    event Unsubscribe(address indexed channel, address indexed user);

    SignatureVerifier verifierContract;

    function setUp() public override {
        BaseTest.setUp();

        changePrank(actor.tim_push_holder);
        verifierContract = new SignatureVerifier();

        changePrank(actor.bob_channel_owner);
        coreProxy.createChannelWithPUSH(
            CoreTypes.ChannelType.InterestBearingOpen,
            _testChannelIdentity,
            50e18,
            0
        );
    }

    modifier whenUserSubscribesWith712Sig() {
        _;
    }

    function testFail_WhenMaliciousUserReplaysA712Signature()
        public
        whenUserSubscribesWith712Sig
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                actor.alice_channel_owner,
                commProxy.nonces(actor.alice_channel_owner),
                block.timestamp + 1000
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.alice_channel_owner],
            digest
        );

        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            actor.alice_channel_owner,
            commProxy.nonces(actor.alice_channel_owner),
            block.timestamp + 1000,
            v,
            r,
            s
        );
        uint oldNonce = commProxy.nonces(actor.alice_channel_owner) - 1;
        changePrank(actor.charlie_channel_owner);
        // Revert fails for unknown reason - Needs to be fixed
        //vm.expectRevert(bytes("PushCommV2::subscribeBySig: Invalid nonce"));
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            actor.alice_channel_owner,
            oldNonce,
            block.timestamp + 1000,
            v,
            r,
            s
        );
    }

    function test_WhenAnExpired712SignatureIsPassed()
        public
        whenUserSubscribesWith712Sig
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                actor.alice_channel_owner,
                commProxy.nonces(actor.alice_channel_owner),
                block.timestamp - 10
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.alice_channel_owner],
            digest
        );
        uint Nonce = commProxy.nonces(actor.alice_channel_owner);
        changePrank(actor.charlie_channel_owner);

        vm.expectRevert();
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            actor.alice_channel_owner,
            Nonce,
            block.timestamp - 10,
            v,
            r,
            s
        );
    }

    function test_WhenThe712SignIsCorrect()
        public
        whenUserSubscribesWith712Sig
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                actor.alice_channel_owner,
                commProxy.nonces(actor.alice_channel_owner),
                block.timestamp + 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.alice_channel_owner],
            digest
        );
        vm.expectEmit(true, true, false, false);
        emit Subscribe(actor.bob_channel_owner, actor.alice_channel_owner);
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            actor.alice_channel_owner,
            commProxy.nonces(actor.alice_channel_owner),
            block.timestamp + 100,
            v,
            r,
            s
        );
    }

    modifier whenAContractSubscribesWith1271Sign() {
        _;
    }

    function test_WhenMaliciousUserReplaysA1271Sig()
        public
        whenAContractSubscribesWith1271Sign
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                address(verifierContract),
                commProxy.nonces(address(verifierContract)),
                block.timestamp + 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.tim_push_holder],
            digest
        );
        vm.expectEmit(true, true, false, false);
        emit Subscribe(actor.bob_channel_owner, address(verifierContract));
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            commProxy.nonces(address(verifierContract)),
            block.timestamp + 100,
            v,
            r,
            s
        );
        uint oldNonce = commProxy.nonces(address(verifierContract)) - 1;

        changePrank(actor.charlie_channel_owner);
        vm.expectRevert();
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            oldNonce,
            block.timestamp + 100,
            v,
            r,
            s
        );
    }

    function test_WhenAnExpired1271SigIsPassed()
        public
        whenAContractSubscribesWith1271Sign
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                address(verifierContract),
                commProxy.nonces(address(verifierContract)),
                block.timestamp - 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.tim_push_holder],
            digest
        );
        uint Nonce = commProxy.nonces(address(verifierContract));

        changePrank(actor.charlie_channel_owner);
        vm.expectRevert();
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            Nonce,
            block.timestamp - 100,
            v,
            r,
            s
        );
    }

    function test_WhenThe1271SignIsCorrect()
        public
        whenAContractSubscribesWith1271Sign
    {
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                address(verifierContract),
                commProxy.nonces(address(verifierContract)),
                block.timestamp + 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.tim_push_holder],
            digest
        );
        vm.expectEmit(true, true, false, false);
        emit Subscribe(actor.bob_channel_owner, address(verifierContract));
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            commProxy.nonces(address(verifierContract)),
            block.timestamp + 100,
            v,
            r,
            s
        );
    }

    function test_WhenUsersUnsubscribeWith712Sig() public {
        //Alice subscribes to bob's channel to check the unsubscribe function
        changePrank(actor.alice_channel_owner);
        bool res = commProxy.subscribe(actor.bob_channel_owner);
        assertEq(res, true);

        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                actor.alice_channel_owner,
                commProxy.nonces(actor.alice_channel_owner),
                block.timestamp + 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            UNSUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.alice_channel_owner],
            digest
        );
        vm.expectEmit(true, true, false, false);
        emit Unsubscribe(actor.bob_channel_owner, actor.alice_channel_owner);
        commProxy.unsubscribeBySig(
            actor.bob_channel_owner,
            actor.alice_channel_owner,
            commProxy.nonces(actor.alice_channel_owner),
            block.timestamp + 100,
            v,
            r,
            s
        );
    }

    function test_WhenAContractUnsubscribesWith1271Sig() public {
        // it Allow contract to optout using 1271 support

        //The contract subscribes to a channel
        bytes32 DOMAIN_SEPARATOR = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                address(verifierContract),
                commProxy.nonces(address(verifierContract)),
                block.timestamp + 100
            );
        bytes32 structHash = getStructHash(
            _subscribeUnsubscribe,
            SUBSCRIBE_TYPEHASH
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKeys[actor.tim_push_holder],
            digest
        );
        vm.expectEmit(true, true, false, false);
        emit Subscribe(actor.bob_channel_owner, address(verifierContract));
        commProxy.subscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            commProxy.nonces(address(verifierContract)),
            block.timestamp + 100,
            v,
            r,
            s
        );

        //check the unsubscribe function
        bytes32 DOMAIN_SEPARATOR1 = getDomainSeparator();
        SubscribeUnsubscribe
            memory _subscribeUnsubscribe1 = SubscribeUnsubscribe(
                actor.bob_channel_owner,
                address(verifierContract),
                commProxy.nonces(address(verifierContract)),
                block.timestamp + 100
            );
        bytes32 structHash1 = getStructHash(
            _subscribeUnsubscribe1,
            UNSUBSCRIBE_TYPEHASH
        );
        bytes32 digest1 = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR1, structHash1)
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            privateKeys[actor.tim_push_holder],
            digest1
        );
        vm.expectEmit(true, true, false, false);
        emit Unsubscribe(actor.bob_channel_owner, address(verifierContract));
        commProxy.unsubscribeBySig(
            actor.bob_channel_owner,
            address(verifierContract),
            commProxy.nonces(address(verifierContract)),
            block.timestamp + 100,
            v1,
            r1,
            s1
        );
    }

    //Helper Functions
    struct SubscribeUnsubscribe {
        address _channel;
        address _subscriber;
        uint nonce;
        uint expiry;
    }

    // computes the hash of a sendNotif
    function getStructHash(
        SubscribeUnsubscribe memory _subscribeUnsubscribe,
        bytes32 _typehash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _typehash,
                    _subscribeUnsubscribe._channel,
                    _subscribeUnsubscribe._subscriber,
                    _subscribeUnsubscribe.nonce,
                    _subscribeUnsubscribe.expiry
                )
            );
    }

    function getDomainSeparator() public returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    NAME_HASH,
                    block.chainid,
                    address(commProxy)
                )
            );
    }
}