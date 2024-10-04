# Ether Lotto

Ether Lotto is a decentralized lottery application built on Ethereum using Foundry for development and testing. It leverages Chainlink VRF for secure randomness and Chainlink Automation for maintaining the lottery state.

This README provides a comprehensive overview of the Ether Lotto project, including installation instructions, usage guidelines, project structure, and information on testing and deployment.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Deployment](#deployment)
- [Scripts](#scripts)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Overview

Ether Lotto is a smart contract-based lottery system that allows users to participate in secure, transparent lottery draws on the Ethereum blockchain. It uses Chainlink VRF (Verifiable Random Function) to ensure fair and verifiable randomness in winner selection.

## Features

- Decentralized lottery system
- Chainlink VRF integration for secure randomness
- Chainlink Automation for automatic lottery state management
- Configurable entrance fee and lottery interval
- Support for multiple networks (Sepolia, Fuji, and local development)
- Comprehensive test suite

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)

## Installation

1. Clone the repository:

   ```
   git clone https://github.com/Patrick-Ehimen/ether-lotto.git
   cd ether-lotto
   ```

2. Install dependencies:

```makefile
   make install
```

## Usage

### Build

Compile the smart contracts:

```makefile
make build
```

### Test

Run the test suite:

```makefile
make test
```

### Deploy

Deploy the Ether Lotto contract:

```makefile
make deploy
```

## Project Structure

- `src/`: Smart contract source files
  - `EtherLotto.sol`: Main lottery contract
  - `constants/`: Constants used across the project
- `test/`: Test files
  - `unit/`: Unit tests for the EtherLotto contract
- `script/`: Deployment and interaction scripts
- `lib/`: External libraries and dependencies

## Testing

The project includes a comprehensive test suite in the `test/unit/EtherLotto.t.sol` file. Run the tests using:

```makefile
make test
```

## Deployment

The `DeployEtherLotto.s.sol` script handles the deployment of the Ether Lotto contract. It uses the `HelperConfig` to manage network-specific configurations.

## Scripts

- `DeployEtherLotto.s.sol`: Deploys the Ether Lotto contract
- `Interactions.s.sol`: Contains scripts for creating subscriptions, adding consumers, and funding subscriptions
- `HelperConfig.s.sol`: Manages network-specific configurations

## Configuration

The `HelperConfig.s.sol` file contains network-specific configurations for different chains (Fuji, Sepolia, and local development). Update this file to add or modify network configurations.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
