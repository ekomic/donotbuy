// File: BankOfLinea.sol
// Author: [BankOfLinea]
// Date:- May, 2025.

/**
 * @title BankOfLinea
 * @dev ERC20 token contract with advanced fee mechanisms, dividend distribution, and trading restrictions.
 *      Implements a reward system where fees are collected and distributed to token holders as dividends.
 *      Includes features like anti-bot measures, max transaction limits, and liquidity pool integration.
 *      Utilizes SafeMath for arithmetic operations and integrates with a decentralized exchange router.
 *
 * Key Features:
 * - **Tokenomics**: Configurable fees for marketing, development, and rewards.
 * - **Dividend System**: Distributes ETH rewards to eligible shareholders based on token holdings.
 * - **Trading Controls**: Enforces max transaction, max sell, and max wallet limits to prevent abuse.
 * - **Fee Exemptions**: Allows specific addresses to be exempt from fees and dividend distributions.
 * - **Swap and Liquify**: Automatically swaps tokens for ETH to fund rewards and other fee receivers.
 *
 *
 * Important Notes:
 * - The contract uses Solidity version 0.8.26, which includes built-in overflow checks, but SafeMath is still used for consistency.
 * - Fees are capped at 15% for total, sell, and transfer transactions to ensure fairness.
 * - The dividend distribution mechanism requires sufficient gas and relies on external calls for ETH transfers.
 * - Ensure the router and pair addresses are correctly set before enabling trading.
 * - The contract includes rescue functions for stuck ERC20 tokens and excess ETH, callable only by the owner.
 *
 * License: This contract is licensed under the MIT License.
 * 
 * https://bankoflinea.build/
 * https://linktr.ee/bankoflinea
 * https://x.com/bankoflinea
 * 
 */
