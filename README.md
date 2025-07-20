# Cache Pyth

A decentralized price feed caching mechanism for financial data on the Stacks blockchain, enabling efficient and reliable price information retrieval.

## Overview

Cache Pyth is a specialized smart contract built on the Stacks blockchain that allows:
- Caching of Pyth Network price feeds
- Efficient price data storage and retrieval
- Price validation and historical tracking
- Low-cost price feed access
- Secure and decentralized price information management

Key features:
- Optimized price feed caching
- Minimal storage overhead
- Historical price tracking
- Cross-chain price data support
- Robust validation mechanisms

## Architecture

The marketplace is built around a single core smart contract that handles all marketplace operations:

```mermaid
graph TD
    A[Creator] -->|Create Listing| B[Marketplace Contract]
    C[Buyer] -->|Purchase Asset| B
    B -->|Record Sale| D[Ownership History]
    B -->|Update Trends| E[Category Trends]
    C -->|Submit Review| F[Review System]
    B -->|Calculate Fees| G[Payment Distribution]
    G -->|Platform Fee| H[Contract Owner]
    G -->|Payment| A
    B -->|Secondary Sale| I[Royalty Distribution]
```

### Core Components:
1. **Listing Management**: Creation, updating, and removal of asset listings
2. **Purchase System**: Secure buying process with automatic fee distribution
3. **Ownership Tracking**: Historical record of asset ownership
4. **Review System**: Buyer feedback and rating mechanism
5. **Trend Analysis**: Purchase tracking by category and time period

## Contract Documentation

### TrendCraft Marketplace Contract

The main contract (`trendcraft-marketplace.clar`) manages all marketplace operations.

#### Key Features

- **Listing Management**
  - Create, update, and remove listings
  - Set prices and royalty percentages
  - Store asset metadata and URLs

- **Purchase Processing**
  - Handle secure transactions
  - Distribute platform fees
  - Record ownership changes
  - Update trend data

- **Review System**
  - Submit and store reviews
  - Track review status
  - Limit one review per purchase

#### Access Control
- Only listing creators can modify their listings
- Only buyers can submit reviews for purchased assets
- Platform fees are sent to the contract owner
- Maximum royalty percentage is capped at 15%

## Getting Started

### Prerequisites
- Clarinet
- Stacks wallet
- STX tokens for transactions

### Basic Usage

1. **Creating a Listing**
```clarity
(contract-call? .trendcraft-marketplace create-listing 
    "My Design Template"
    "A professional design template"
    u1000000 ;; Price in µSTX
    "templates"
    "preview-url"
    "full-asset-url"
    u10 ;; 10% royalty
)
```

2. **Purchasing an Asset**
```clarity
(contract-call? .trendcraft-marketplace purchase-asset u1)
```

3. **Submitting a Review**
```clarity
(contract-call? .trendcraft-marketplace submit-review 
    u1 ;; listing-id
    u5 ;; score
    "Great asset!"
)
```

## Function Reference

### Public Functions

#### Listing Management
```clarity
(create-listing (title (string-ascii 100)) 
                (description (string-utf8 500)) 
                (price uint) 
                (category (string-ascii 50))
                (preview-url (string-utf8 200))
                (full-asset-url (string-utf8 200))
                (royalty-percent uint))

(update-listing (listing-id uint) ...)
(remove-listing (listing-id uint))
```

#### Transaction Functions
```clarity
(purchase-asset (listing-id uint))
(resell-asset (listing-id uint) (new-price uint))
```

#### Review System
```clarity
(submit-review (listing-id uint) (score uint) (comment (string-utf8 300)))
```

### Read-Only Functions
```clarity
(get-listing (listing-id uint))
(has-purchased (listing-id uint) (user principal))
(get-review (listing-id uint) (reviewer principal))
(get-category-trend (category (string-ascii 50)) (month-year (string-ascii 7)))
(get-ownership-history (listing-id uint) (index uint))
```

## Development

### Testing
1. Install Clarinet
2. Clone the repository
3. Run tests:
```bash
clarinet test
```

### Local Development
1. Start Clarinet console:
```bash
clarinet console
```
2. Deploy contract:
```clarity
(contract-call? .trendcraft-marketplace ...)
```

## Security Considerations

### Limitations
- Asset URLs are stored on-chain as strings
- Trend analysis is based on block height for time approximation
- Review scores are limited to 0-5 range

### Best Practices
- Verify asset ownership before reselling
- Check listing status before purchasing
- Keep sufficient STX for platform fees
- Review asset details and seller reputation before purchasing
- Ensure listing prices are set in µSTX (multiply by 1,000,000)