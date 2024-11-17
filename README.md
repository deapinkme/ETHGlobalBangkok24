# Interest-Bearing Stablecoin

This is a project for creating an **Interest-Bearing Stablecoin** powered by a smart contract. The stablecoin allows users to deposit USDC, convert it to STETH (Ethereum staking tokens), and withdraw the principal with accrued interest over time. The interest is calculated using a **Chronicle Labs Oracle** to fetch live interest rates, and the contract ensures secure and transparent handling of deposits and withdrawals.

## Features

- **Deposit**: Users can deposit USDC, which gets converted to STETH.
- **Interest Accrual**: Interest is calculated based on the time elapsed since the deposit, fetched from the **Chronicle Labs Oracle**.
- **Withdraw**: Users can withdraw their USDC principal along with the accrued interest after the specified duration.
- **Trading Bot**: A Python trading bot that interacts with the smart contract and can perform trading activities to increase profits (buy/sell ETH to USDC).

## Project Structure

- `contracts/` - Contains Solidity smart contracts for the stablecoin.
- `scripts/` - Contains deployment scripts and contract interaction scripts.
- `src/` - Additional smart contract code for various functionalities.
- `test/` - Solidity test files to ensure the contract logic works as expected.
- `python/` - Contains the Python trading bot script for interacting with the smart contract.

## Prerequisites

- **Node.js**: Needed for Foundry and running Solidity scripts.
- **Foundry**: A toolkit for Ethereum development.
- **Python**: Required to run the trading bot script.

## Installation

### 1. Install Foundry

Follow the Foundry installation guide: [Foundry Setup](https://github.com/foundry-rs/foundry).

### 2. Install Python Dependencies

Ensure you have Python installed. Then, in the `python/` directory, install the required libraries:

```bash
pip install web3