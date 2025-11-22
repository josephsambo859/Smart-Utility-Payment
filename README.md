# ⚡ Smart Utility Payment Contract

A decentralized utility payment system built on Stacks blockchain that enables seamless payments for electricity, water, gas, and other utility services with minimal fees and maximum transparency.

## 🌟 Features

- **Provider Registration**: Utility companies can register and manage their services
- **Bill Creation**: Automated bill generation with due dates and descriptions
- **Secure Payments**: STX-based payments with built-in escrow mechanism
- **Balance Management**: Customer wallet functionality with deposit/withdrawal
- **Fee Structure**: Configurable platform fees with transparent pricing
- **Payment History**: Complete audit trail of all transactions
- **Emergency Controls**: Contract pause functionality and emergency withdrawals

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli) (optional)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/josephsambo859/Smart-Utility-Payment.git
cd Smart-Utility-Payment
```

2. Check contract validity:
```bash
clarinet check
```

3. Run tests:
```bash
npm install
npm test
```

## 📋 Contract Functions

### 👤 Provider Functions

#### Register as a Provider
```clarity
(contract-call? .Smart-Utility-Payment register-provider "Electric Company" "electricity")
```

#### Create a Bill
```clarity
(contract-call? .Smart-Utility-Payment create-bill 'ST1CUSTOMER123 u100000 u1050 "Monthly electricity bill")
```

#### Deactivate Provider
```clarity
(contract-call? .Smart-Utility-Payment deactivate-provider u1)
```

### 💰 Customer Functions

#### Deposit Funds
```clarity
(contract-call? .Smart-Utility-Payment deposit-funds u500000)
```

#### Pay Bill
```clarity
(contract-call? .Smart-Utility-Payment pay-bill u1)
```

#### Withdraw Funds
```clarity
(contract-call? .Smart-Utility-Payment withdraw-funds u100000)
```

### 📊 Read-Only Functions

#### Get Provider Information
```clarity
(contract-call? .Smart-Utility-Payment get-provider u1)
```

#### Get Bill Details
```clarity
(contract-call? .Smart-Utility-Payment get-bill u1)
```

#### Check Customer Balance
```clarity
(contract-call? .Smart-Utility-Payment get-customer-balance 'ST1CUSTOMER123)
```

#### Get Bill Status
```clarity
(contract-call? .Smart-Utility-Payment get-bill-status u1)
```

## 💡 Usage Examples

### Scenario 1: Electricity Company Setup

1. **Register Provider**:
```clarity
(contract-call? .Smart-Utility-Payment register-provider "PowerGrid Co" "electricity")
```

2. **Create Customer Bill**:
```clarity
(contract-call? .Smart-Utility-Payment create-bill 'ST1CUSTOMER123 u150000 u1100 "March 2024 electricity usage")
```

### Scenario 2: Customer Payment Flow

1. **Check Bill Details**:
```clarity
(contract-call? .Smart-Utility-Payment get-bill u1)
```

2. **Deposit Funds**:
```clarity
(contract-call? .Smart-Utility-Payment deposit-funds u200000)
```

3. **Pay Bill**:
```clarity
(contract-call? .Smart-Utility-Payment pay-bill u1)
```

## 💵 Fee Structure

- **Platform Fee**: Configurable percentage (default: 0.5%)
- **Payment Fee**: Calculated automatically on each transaction
- **No Hidden Charges**: All fees are transparent and visible

## 🔒 Security Features

- **Owner-only Functions**: Critical operations restricted to contract owner
- **Input Validation**: All parameters validated before processing
- **Pause Mechanism**: Emergency contract pause functionality
- **Expiry Checks**: Bills cannot be paid after due date
- **Balance Verification**: Insufficient fund protection

## 🏗️ Contract Architecture

The contract uses several data maps to organize information:

- `providers`: Store utility company details
- `bills`: Individual bill records with payment status
- `customer-balances`: Track customer STX balances
- `payment-history`: Complete transaction audit trail

## ⚠️ Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-found` | Requested resource doesn't exist |
| u102 | `err-already-exists` | Resource already exists |
| u103 | `err-insufficient-funds` | Not enough balance for operation |
| u104 | `err-invalid-amount` | Invalid amount provided |
| u105 | `err-unauthorized` | Unauthorized access attempt |
| u106 | `err-bill-already-paid` | Bill has already been paid |
| u107 | `err-bill-expired` | Bill past due date |
| u108 | `err-invalid-provider` | Provider not found or inactive |

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

## 📈 Future Enhancements

- 🔔 Bill notification system
- 📅 Recurring payment automation
- 🎯 Multi-token payment support
- 📱 Mobile app integration
- 🏪 Marketplace for utility providers


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the Stacks ecosystem**
