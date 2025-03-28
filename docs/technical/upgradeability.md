# Contract Upgradeability

This document discusses the strategy for upgrading smart contracts within the DeFi & Dragons project, primarily focusing on the proxy patterns commonly used with Foundry.

## Why Upgradeability?

Smart contracts deployed on blockchains like Ethereum are immutable by default. Upgradeability patterns allow developers to modify contract logic post-deployment without requiring users to migrate to a new contract address. This is crucial for:

*   **Bug Fixes:** Addressing vulnerabilities discovered after launch.
*   **Feature Additions:** Introducing new game mechanics or DeFi integrations.
*   **Optimizations:** Improving gas efficiency or performance.

## Chosen Upgrade Pattern

*(Specify the pattern used, e.g., UUPS, Transparent Proxy, Beacon Proxy)*

*   **UUPS (Universal Upgradeable Proxy Standard - EIP-1822):**
    *   **Pros:** More gas efficient on deployment and upgrades compared to Transparent Proxies. Upgrade logic resides in the implementation contract.
    *   **Cons:** Requires careful implementation to avoid storage collisions and ensure the upgrade function cannot be bricked.
*   **Transparent Proxy (OpenZeppelin Standard):**
    *   **Pros:** Robust and well-understood pattern. Clear separation of admin logic (in the proxy) and business logic (in the implementation).
    *   **Cons:** Higher deployment and upgrade gas costs. Potential for function selector clashes between proxy admin functions and implementation functions (mitigated by the transparent nature).
*   **Beacon Proxy (EIP-1167 Minimal Proxy + Beacon):**
    *   **Pros:** Extremely gas-efficient for deploying multiple proxy instances that share the same implementation logic. Upgrading the beacon upgrades all associated proxies simultaneously.
    *   **Cons:** Adds complexity with the extra beacon contract. Not suitable if individual proxies need different upgrade cadences.

**[Decision]:** *State which pattern is primarily used in DeFi & Dragons and why.*

## Implementation Details (Example for UUPS)

*   **Contracts:** Utilize OpenZeppelin's `UUPSUpgradeable` contract.
*   **Inheritance:** Inherit `UUPSUpgradeable` and an `Initializable` contract.
*   **Initializers:** Use initializer functions (`initializer` modifier) instead of constructors for setup logic.
*   **Upgrade Function:** Implement an `_authorizeUpgrade` function, typically restricted by access control (e.g., `onlyOwner`, `onlyRole(UPGRADER_ROLE)`).
*   **Storage Layout:** Maintain storage layout compatibility between upgrades to prevent storage corruption. Avoid changing the order of state variables, removing variables, or changing their types. Append new variables only.
*   **Using `@openzeppelin/contracts-upgradeable`:** Ensure all inherited OpenZeppelin contracts are from the `-upgradeable` package.

## Upgrade Process (Using Foundry)

*(Outline the steps for performing an upgrade)*

1.  **Develop New Implementation:** Create the V2 (or subsequent version) of the contract logic (`MyContractV2.sol`). Ensure it maintains storage compatibility with V1.
2.  **Test Thoroughly:** Write extensive tests for the new implementation and ensure upgrade compatibility (Foundry offers tools for storage layout checking).
3.  **Deploy New Implementation:** Deploy the `MyContractV2.sol` contract normally.
    ```bash
    # Example: Deploying the new implementation
    forge create src/MyContractV2.sol:MyContractV2 --rpc-url $RPC_URL_SEPOLIA --private-key $ADMIN_PRIVATE_KEY
    # Note the deployed address of the new implementation
    ```
4.  **Prepare Upgrade Transaction:** Use `cast` or a Foundry script to call the upgrade function on the *proxy* contract.
    *   **UUPS Example:** Call `upgradeTo(address newImplementation)` on the proxy.
    *   **Transparent Proxy Example:** Call `upgrade(address proxy, address newImplementation)` on the `ProxyAdmin` contract associated with the proxy.

    ```bash
    # Example using cast to call upgradeTo (UUPS) on the proxy
    cast send <PROXY_ADDRESS> "upgradeTo(address)" <NEW_IMPLEMENTATION_ADDRESS> --rpc-url $RPC_URL_SEPOLIA --private-key $ADMIN_PRIVATE_KEY
    ```

    ```bash
    # Example using cast to call upgrade (Transparent Proxy) on the ProxyAdmin
    cast send <PROXY_ADMIN_ADDRESS> "upgrade(address,address)" <PROXY_ADDRESS> <NEW_IMPLEMENTATION_ADDRESS> --rpc-url $RPC_URL_SEPOLIA --private-key $ADMIN_PRIVATE_KEY
    ```

5.  **Verify Upgrade:** Interact with the proxy contract to confirm the new logic is active and the state is preserved.
6.  **Verify New Implementation:** Verify the new implementation contract on Etherscan.

## Upgrade Governance

*(Describe who has the authority to perform upgrades)*

*   **Single Admin Key:** A single EOA (Externally Owned Account) controls upgrades. Simple but centralized.
*   **Multisig Wallet:** Requires signatures from multiple parties (e.g., core dev team members) stored in a Gnosis Safe or similar multisig.
*   **Timelock Contract:** Introduces a mandatory delay between proposing an upgrade and executing it, allowing users time to react or exit if they disagree.
*   **DAO Governance:** Token holders vote on upgrade proposals.

**[Decision]:** *Specify the governance mechanism used for upgrades in DeFi & Dragons (e.g., Multisig controlled by the core team with a 24-hour timelock).*

## Security Considerations

*   **Storage Collisions:** Carefully manage storage layouts across upgrades.
*   **Initialization:** Ensure implementation contracts cannot be initialized independently (`disableInitializers` in OpenZeppelin).
*   **Upgrade Authorization:** Securely manage the keys/roles authorized to perform upgrades.
*   **Testing:** Rigorous testing of upgrade processes in a testnet environment is critical.
*   **Audits:** Have upgrade mechanisms and new implementations audited.

## Related Links

*   [OpenZeppelin Docs: Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
*   [OpenZeppelin Docs: Upgrade Patterns](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
*   [Foundry Book](https://book.getfoundry.sh/)
*   [EIP-1822: UUPS](https://eips.ethereum.org/EIPS/eip-1822)
*   [Contract Deployment](./deployment.md)
*   [Security Considerations](./security.md) *(Link to be created)* 