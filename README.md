# MetalForge 🏭

**Synthetic Assets for Precious Metals on Stacks Blockchain**

MetalForge is a decentralized finance (DeFi) protocol that enables users to create synthetic exposure to precious metals (Silver, Platinum, Palladium) using STX as collateral. Built on the Stacks blockchain using Clarity smart contracts.

## ✨ Features

- **Synthetic Metal Tokens**: Mint tokens representing Silver, Platinum, and Palladium
- **Over-Collateralized Positions**: 150% collateralization ratio ensures protocol stability
- **Oracle Price Feeds**: Real-time price updates for accurate asset valuation
- **Decentralized Trading**: Transfer synthetic tokens between users
- **Collateral Management**: Mint by depositing STX, burn to retrieve collateral
- **Price Validity Checks**: Automated safeguards against stale price data
- **Multi-Metal Support**: Three distinct precious metal synthetic assets

## 🔧 Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Collateral Asset**: STX
- **Collateral Ratio**: 150% (1.5x over-collateralized)
- **Price Validity Window**: 144 blocks (~24 hours)

### Supported Metals

| Metal | ID | Initial Price | Token Symbol |
|-------|----|--------------|--------------| 
| Silver | 1 | $30/oz | synthetic-silver |
| Platinum | 2 | $1000/oz | synthetic-platinum |
| Palladium | 3 | $2000/oz | synthetic-palladium |

## 📦 Installation

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet/)
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Stacks Wallet](https://www.hiro.so/wallet) for testnet/mainnet interaction

### Development Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd MetalForge
```

2. **Navigate to contract directory**
```bash
cd MetalForge_contract
```

3. **Install dependencies**
```bash
npm install
```

4. **Run tests**
```bash
npm run test
```

5. **Start local development**
```bash
clarinet console
```

## 🚀 Usage Examples

### Basic Operations

#### 1. Mint Synthetic Silver
```clarity
;; Mint 1 ounce of synthetic silver (requires ~$45 worth of STX as collateral)
(contract-call? .MetalForge mint-synthetic u1 u1000000) ;; 1 million micro-tokens = 1 token
```

#### 2. Check Metal Price
```clarity
;; Get current silver price
(contract-call? .MetalForge get-price u1)

;; Get platinum price  
(contract-call? .MetalForge get-price u2)
```

#### 3. Transfer Synthetic Tokens
```clarity
;; Transfer 0.5 ounces of synthetic silver to another user
(contract-call? .MetalForge transfer-synthetic u1 u500000 'ST1RECIPIENT_ADDRESS)
```

#### 4. Burn Tokens and Retrieve Collateral
```clarity
;; Burn 1 ounce of synthetic silver to get collateral back
(contract-call? .MetalForge burn-synthetic u1 u1000000)
```

#### 5. Check User Balance
```clarity
;; Check your synthetic silver balance
(contract-call? .MetalForge get-user-balance 'ST1YOUR_ADDRESS u1)
```

## 📚 Contract Functions Documentation

### Public Functions

#### Administrative Functions

**`set-oracle-address(new-oracle: principal)`**
- Sets the authorized oracle address (owner only)
- Used to update price feed provider

**`update-price(metal: uint, new-price: uint)`**
- Updates metal price (oracle only)
- Validates metal ID and price > 0
- Updates price timestamp

#### Core Trading Functions

**`mint-synthetic(metal: uint, amount: uint)`**
- Mints synthetic metal tokens by depositing STX collateral
- Requires 150% collateralization
- Validates price freshness (within 24 hours)
- Parameters:
  - `metal`: Metal ID (1=Silver, 2=Platinum, 3=Palladium)
  - `amount`: Amount to mint in micro-tokens (1M = 1 token)

**`burn-synthetic(metal: uint, amount: uint)`**
- Burns synthetic tokens and returns proportional collateral
- Validates sufficient token balance
- Returns STX collateral to user

**`transfer-synthetic(metal: uint, amount: uint, recipient: principal)`**
- Transfers synthetic tokens between users
- Standard fungible token transfer

### Read-Only Functions

**`get-price(metal: uint) -> uint`**
- Returns current price for specified metal

**`get-price-updated(metal: uint) -> uint`**
- Returns block height of last price update

**`is-price-valid(metal: uint) -> bool`**
- Checks if price was updated within validity window

**`calculate-collateral-needed(metal: uint, amount: uint) -> uint`**
- Calculates required STX collateral for minting

**`get-user-balance(user: principal, metal: uint) -> uint`**
- Returns user's synthetic token balance

**`get-user-collateral(user: principal, metal: uint) -> uint`**
- Returns user's deposited collateral for specific metal

**`get-total-supply(metal: uint) -> uint`**
- Returns total supply of synthetic tokens for metal

**`get-contract-owner() -> principal`**
- Returns contract owner address

**`get-oracle-address() -> principal`**
- Returns authorized oracle address

**`get-metal-name(metal: uint) -> string`**
- Returns metal name string for given ID

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR-OWNER-ONLY | Function restricted to contract owner |
| 101 | ERR-NOT-AUTHORIZED | Caller not authorized for this operation |
| 102 | ERR-INVALID-AMOUNT | Amount must be greater than zero |
| 103 | ERR-INSUFFICIENT-BALANCE | Insufficient token balance |
| 104 | ERR-INVALID-METAL | Invalid metal identifier |
| 105 | ERR-PRICE-TOO-OLD | Price data is stale |
| 106 | ERR-COLLATERAL-INSUFFICIENT | Insufficient collateral provided |

## 🌐 Deployment Guide

### Testnet Deployment

1. **Configure Clarinet for testnet**
```bash
clarinet deployments generate --testnet
```

2. **Deploy contract**
```bash
clarinet deployments apply -p testnet
```

### Mainnet Deployment

1. **Configure mainnet deployment**
```bash
clarinet deployments generate --mainnet
```

2. **Review deployment plan**
```bash
clarinet deployments apply -p mainnet --dry-run
```

3. **Deploy to mainnet**
```bash
clarinet deployments apply -p mainnet
```

### Post-Deployment Setup

1. **Set Oracle Address** (if different from deployer)
```bash
stx call_contract_func <DEPLOYER_ADDRESS> MetalForge set-oracle-address <ORACLE_ADDRESS>
```

2. **Initialize Metal Prices**
```bash
# Update silver price
stx call_contract_func <ORACLE_ADDRESS> MetalForge update-price 1 <SILVER_PRICE>

# Update platinum price  
stx call_contract_func <ORACLE_ADDRESS> MetalForge update-price 2 <PLATINUM_PRICE>

# Update palladium price
stx call_contract_func <ORACLE_ADDRESS> MetalForge update-price 3 <PALLADIUM_PRICE>
```

## 🔒 Security Considerations

### Oracle Risk
- **Single Point of Failure**: Contract relies on single oracle for price feeds
- **Price Manipulation**: Malicious oracle could manipulate prices
- **Mitigation**: Implement multi-oracle system and price deviation checks

### Collateralization Risk
- **Market Volatility**: STX price volatility affects collateral value
- **Liquidation Risk**: No automated liquidation mechanism for under-collateralized positions
- **Mitigation**: 150% over-collateralization provides buffer

### Smart Contract Risk
- **Code Bugs**: Potential vulnerabilities in contract logic
- **Upgrade Risk**: No upgrade mechanism - contract is immutable
- **Mitigation**: Thorough testing and security audits recommended

### Operational Risk
- **Oracle Downtime**: Stale prices prevent minting/burning
- **Key Management**: Oracle and owner private key security critical
- **Mitigation**: Implement backup oracle systems and secure key management

## 🧪 Testing

### Run Unit Tests
```bash
npm run test
```

### Watch Mode (Auto-rerun on changes)
```bash
npm run test:watch
```

### Coverage Report
```bash
npm run test:report
```

### Manual Testing
```bash
clarinet console
```

Example test scenarios:
```clarity
;; Test minting
(contract-call? .MetalForge mint-synthetic u1 u1000000)

;; Test price updates (as oracle)
(contract-call? .MetalForge update-price u1 u35000000)

;; Test transfers
(contract-call? .MetalForge transfer-synthetic u1 u500000 'ST1EXAMPLE)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass (`npm run test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details.

## ⚠️ Disclaimer

MetalForge is experimental DeFi software. Use at your own risk. The protocol has not been audited and may contain bugs or vulnerabilities. Never invest more than you can afford to lose. Synthetic tokens do not represent actual ownership of physical metals.

## 📞 Support

- **Documentation**: [Stacks Docs](https://docs.stacks.co/)
- **Clarity Language**: [Clarity Reference](https://docs.stacks.co/clarity/)
- **Issues**: GitHub Issues
- **Community**: [Stacks Discord](https://discord.gg/stacks)

---

**Built with ❤️ on Stacks blockchain**