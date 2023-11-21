/** CHECKLISTS BEFORE RUNNING THE SCRIPTS
 * @dev
 *  ->The correct proxy address and Admin Address should be mentioned
 *  ->make sure to check the env has a Private Key named PRIVATE.
 *  ->Check the file imports, mention the correct files,
 *  ->that is supposed to be the new implemntetion
 * -> If the Proxy and Admin are the <OZ v5 then use upgrade. If  > OZv5, use upgradeAndCall
 * 
 * Command to Run -> forge script .\script\UpgradeCore.s.sol --rpc-url <YOUR RPC URL> --broadcast
 */
import "forge-std/Script.sol";
import "forge-std/console.sol";

import "contracts/PushCore/PushCoreV2_5.sol";
import "contracts/PushCore/EPNSCoreAdmin.sol";

contract DeployCore is Script {
    ITransparentUpgradeableProxy ProxyAddress =
        ITransparentUpgradeableProxy(
            0xeFD6d2B7dB3bEa7dfFCFB69e980D159B3810198A
        );
    address AdminAddress = 0xC44F94dDC6a44ebD4EF6Ec6421252445EaBCeae3;

    function run() public {
       
        uint pvkey = vm.envUint("PRIVATE");
        address acc = vm.addr(pvkey);
        vm.startBroadcast(pvkey);
        PushCoreV2_5 implementation = new PushCoreV2_5();
        EPNSCoreAdmin admin = EPNSCoreAdmin(AdminAddress);

        // admin.upgrade(ProxyAddress, implementation);
        admin.upgradeAndCall(ProxyAddress, address(implementation), "");
        vm.stopBroadcast();
        console.log("upgraded to ", address(implementation));
    }
}
