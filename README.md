# W Swap Smart Contracts

## Overview

**W Swap** is a decentralized exchange (DEX) protocol based on the Uniswap V2 Automated Market Maker (AMM) model. It enables trustless token swaps and liquidity provision on the W Chain.

This repository contains the core smart contracts for the W Swap protocol, including the Factory, Pairs, and LP Tokens.

## Architecture

The W Swap protocol consists of three main components:

1.  **WSwapV2Factory**: The core registry that deploys and tracks all Pair contracts.
2.  **WSwapV2Pair**: The AMM contract that holds liquidity for a specific token pair and executes swaps.
3.  **WSwapV2ERC20**: The LP token implementation, inherited by the Pair contract.

### System Diagram

```mermaid
classDiagram
    class WSwapV2Factory {
        +getPair(tokenA, tokenB) address
        +allPairs(uint) address
        +allPairsLength() uint
        +createPair(tokenA, tokenB) address
        +feeTo() address
        +feeToSetter() address
        +setFeeTo(address)
        +setFeeToSetter(address)
    }

    class WSwapV2Pair {
        +MINIMUM_LIQUIDITY uint
        +factory() address
        +token0() address
        +token1() address
        +getReserves() (uint112, uint112, uint32)
        +price0CumulativeLast() uint
        +price1CumulativeLast() uint
        +kLast() uint
        +mint(to) uint
        +burn(to) (uint, uint)
        +swap(amount0Out, amount1Out, to, data)
        +skim(to)
        +sync()
        +initialize(token0, token1)
    }

    class WSwapV2ERC20 {
        +name() string
        +symbol() string
        +decimals() uint8
        +totalSupply() uint
        +balanceOf(owner) uint
        +allowance(owner, spender) uint
        +approve(spender, value) bool
        +transfer(to, value) bool
        +transferFrom(from, to, value) bool
        +DOMAIN_SEPARATOR() bytes32
        +PERMIT_TYPEHASH() bytes32
        +nonces(owner) uint
        +permit(owner, spender, value, deadline, v, r, s)
    }

    WSwapV2Factory ..> WSwapV2Pair : Deploys
    WSwapV2Pair --|> WSwapV2ERC20 : Inherits
```

## Core Contracts

### WSwapV2Factory
*   **Location**: `src/WSwapV2Factory.sol`
*   **Role**: Acts as the single source of truth for all W Swap pairs.
*   **Key Functions**:
    *   `createPair(address tokenA, address tokenB)`: Deploys a new Pair contract using `create2` for deterministic addresses.
    *   `setFeeTo(address)`: Sets the recipient of the protocol fee (if enabled).

### WSwapV2Pair
*   **Location**: `src/WSwapV2Pair.sol`
*   **Role**: Stores liquidity and executes swaps for a specific pair of tokens.
*   **Key Logic**:
    *   Implements the constant product formula: `x * y = k`.
    *   Manages reserves (`reserve0`, `reserve1`) and price accumulators.
    *   Supports flash swaps via `IUniswapV2Callee`.

### WSwapV2ERC20
*   **Location**: `src/WSwapV2ERC20.sol`
*   **Role**: ERC-20 implementation for Liquidity Provider (LP) tokens.
*   **Name/Symbol**: `WLP V2` / `WLP-V2`.
*   **Features**: Includes EIP-2612 `permit` for gasless approvals.

## Key Workflows

### 1. Pair Creation
A new pair is created by calling the Factory. This is a one-time setup for each unique token pair.

### 2. Adding Liquidity
Liquidity providers deposit both tokens into the Pair contract and receive LP tokens in return.

```mermaid
sequenceDiagram
    participant User
    participant Pair as WSwapV2Pair
    participant TokenA
    participant TokenB

    Note over User, Pair: User approves tokens first
    User->>TokenA: transfer(Pair, amountA)
    User->>TokenB: transfer(Pair, amountB)
    User->>Pair: mint(to)
    activate Pair
    Pair->>TokenA: balanceOf(Pair)
    Pair->>TokenB: balanceOf(Pair)
    Note right of Pair: Calculate liquidity based on reserves
    Pair->>User: Mint LP Tokens
    Pair->>Pair: _update(balance0, balance1)
    deactivate Pair
```

### 3. Swapping
Users trade one token for another. The Pair ensures the constant product invariant (`k`) is maintained (minus fees).

```mermaid
sequenceDiagram
    participant User
    participant Pair as WSwapV2Pair
    participant InputToken
    participant OutputToken

    Note over User, Pair: User sends input tokens
    User->>InputToken: transfer(Pair, amountIn)
    User->>Pair: swap(amount0Out, amount1Out, to, data)
    activate Pair
    Pair->>InputToken: balanceOf(Pair)
    Pair->>OutputToken: balanceOf(Pair)
    Note right of Pair: Verify: (bal0 - fee) * (bal1 - fee) >= k
    Pair->>OutputToken: transfer(to, amountOut)
    Pair->>Pair: _update(balance0, balance1)
    deactivate Pair
```

### 4. Removing Liquidity
Liquidity providers burn their LP tokens to reclaim their share of the underlying assets.

```mermaid
sequenceDiagram
    participant User
    participant Pair as WSwapV2Pair
    participant TokenA
    participant TokenB

    User->>Pair: transfer(Pair, liquidity)
    User->>Pair: burn(to)
    activate Pair
    Pair->>Pair: burn LP tokens
    Pair->>TokenA: transfer(to, amountA)
    Pair->>TokenB: transfer(to, amountB)
    Pair->>Pair: _update(balance0, balance1)
    deactivate Pair
```

## Development

This project uses [Foundry](https://book.getfoundry.sh/).

### Build

```shell
$ forge build
```

### Test

Tests are located in the `test/` directory.

```shell
$ forge test
```

### Deploy

Create a deployment script in the `script/` directory (e.g., `script/Deploy.s.sol`) and run:

```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```
