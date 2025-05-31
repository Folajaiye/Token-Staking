# Token Staking Smart Contract

## Overview

This is a Clarity smart contract that enables users to stake tokens and earn rewards over time. The contract manages staking positions, calculates rewards based on a fixed rate, and allows users to claim their rewards or unstake their tokens.

## Features

- **Token Staking**: Users can stake their tokens to start earning rewards
- **Reward Calculation**: Rewards are calculated based on:
  - Amount staked
  - Duration of stake
  - Fixed reward rate (1% per 1000 blocks)
- **Reward Claiming**: Users can claim their accumulated rewards at any time
- **Unstaking**: Users can unstake their tokens (automatically claims rewards first)
- **Token Management**: Includes basic token balance tracking for testing purposes

## Contract Details

### Constants

- `contract-owner`: The principal that deployed the contract (has special privileges)
- Error codes for various failure cases

### Data Variables

- `total-staked`: Tracks the total amount of tokens currently staked
- `reward-rate`: Fixed reward rate (1% per 1000 blocks)
- `min-stake-amount`: Minimum amount required to stake (100 tokens)

### Data Maps

- `stakes`: Stores staking information per user:
  - `amount`: Staked amount
  - `start-block`: Block height when staking began
  - `last-claim-block`: Last block when rewards were claimed
  - `total-rewards`: Total rewards earned
- `token-balances`: Tracks token balances for testing purposes

## Public Functions

### Token Management

- `(mint-tokens (recipient principal) (amount uint))`: 
  - Contract owner can mint new tokens (for testing)
  - Returns: `(ok true)` on success

### Staking Functions

- `(stake-tokens (amount uint))`:
  - Stake the specified amount of tokens
  - Must meet minimum stake amount
  - Must have sufficient token balance
  - Returns: `(ok true)` on success

- `(unstake-tokens (amount uint))`:
  - Unstake the specified amount of tokens
  - Automatically claims any pending rewards first
  - Must have sufficient staked amount
  - Returns: `(ok true)` on success

- `(claim-rewards)`:
  - Claim accumulated staking rewards
  - Returns: `(ok reward-amount)` with the claimed amount

### Read-Only Functions

- `(get-stake (staker principal))`:
  - Returns staking information for the specified principal
  - Returns: Stake details or `none` if no stake exists

- `(get-token-balance (holder principal))`:
  - Returns token balance for the specified principal
  - Returns: Balance amount (0 if none)

- `(calculate-pending-rewards (staker principal))`:
  - Calculates pending rewards for a staker
  - Returns: `(ok reward-amount)` (0 if no stake)

- `(get-total-staked)`:
  - Returns the total amount of tokens currently staked
  - Returns: Total staked amount

## Usage Examples

1. **Minting tokens (contract owner only)**:
   ```clarity
   (mint-tokens 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 1000)
   ```

2. **Staking tokens**:
   ```clarity
   (stake-tokens 500)
   ```

3. **Checking stake details**:
   ```clarity
   (get-stake tx-sender)
   ```

4. **Claiming rewards**:
   ```clarity
   (claim-rewards)
   ```

5. **Unstaking tokens**:
   ```clarity
   (unstake-tokens 500)
   ```

## Requirements

- Stacks blockchain environment
- Clarity language support
