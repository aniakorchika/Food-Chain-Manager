# Agricultural Supply Chain Tracking Smart Contract

## Overview

This smart contract enables comprehensive agricultural supply chain management on the Stacks blockchain. It provides a transparent and immutable system for tracking agricultural products from farm to consumer, ensuring product authenticity, quality verification, and complete chain of custody documentation.

## Features

- **Product Registration**: Register new agricultural products with unique identifiers
- **Ownership Tracking**: Monitor product custody across the entire supply chain
- **Quality Verification**: Record and certify product quality assessments
- **Location Tracking**: Document geographic movement of products
- **Transaction History**: Maintain complete and auditable supply chain events
- **Participant Management**: Register and authenticate supply chain participants

## Contract Structure

The contract uses the following data structures:

- `participant-directory`: Maps blockchain addresses to participant roles and status
- `agricultural-products`: Maps product IDs to comprehensive product information
- `supply-chain-events`: Records all product-related events throughout the supply chain

## Public Functions

### Participant Management

#### `register-participant`
Registers a new participant in the supply chain network.
```clarity
(register-participant participant-address participant-role)
```
- `participant-address`: Principal address of the participant
- `participant-role`: Role of the participant (e.g., "farmer", "processor", "distributor")

#### `update-participant-status`
Updates the active status of a participant.
```clarity
(update-participant-status participant-address active-status)
```
- `participant-address`: Principal address of the participant
- `active-status`: Boolean representing the active status

### Product Operations

#### `register-new-product`
Registers a new agricultural product in the system.
```clarity
(register-new-product product-identifier product-name geographic-location initial-price)
```
- `product-identifier`: Unique identifier for the product
- `product-name`: Name of the agricultural product
- `geographic-location`: Origin location of the product
- `initial-price`: Initial market value of the product

#### `update-supply-chain-stage`
Updates the current stage of a product in the supply chain.
```clarity
(update-supply-chain-stage product-identifier new-stage stage-details)
```
- `product-identifier`: ID of the product
- `new-stage`: New supply chain stage (e.g., "harvested", "processed", "packaged")
- `stage-details`: Additional details about the stage change

#### `transfer-product-ownership`
Transfers custody of a product to a new supply chain participant.
```clarity
(transfer-product-ownership product-identifier new-custodian transfer-notes)
```
- `product-identifier`: ID of the product
- `new-custodian`: Principal address of the new custodian
- `transfer-notes`: Details about the ownership transfer

#### `update-quality-assessment`
Records quality assessment information for a product.
```clarity
(update-quality-assessment product-identifier quality-score assessment-details)
```
- `product-identifier`: ID of the product
- `quality-score`: Quality rating (0-100)
- `assessment-details`: Details about the quality assessment

#### `update-product-location`
Updates the geographic location of a product.
```clarity
(update-product-location product-identifier new-location location-details)
```
- `product-identifier`: ID of the product
- `new-location`: New geographic location
- `location-details`: Additional details about the location update

## Read-Only Functions

#### `get-product-information`
Retrieves comprehensive information about a product.
```clarity
(get-product-information product-identifier)
```

#### `get-participant-details`
Retrieves information about a supply chain participant.
```clarity
(get-participant-details participant-address)
```

#### `get-supply-chain-event`
Retrieves details about a specific supply chain event.
```clarity
(get-supply-chain-event product-identifier event-identifier)
```

## Error Codes

- `ERR-UNAUTHORIZED-ACCESS (u1)`: Caller doesn't have permission for the operation
- `ERR-PRODUCT-NOT-FOUND (u2)`: Referenced product doesn't exist
- `ERR-INVALID-STATUS-TRANSITION (u3)`: Invalid supply chain stage transition
- `ERR-DUPLICATE-RECORD (u4)`: Attempting to create a duplicate record
- `ERR-INVALID-INPUT-DATA (u5)`: Input data validation failure

## Deployment Guide

1. Deploy the contract to the Stacks blockchain
2. Initialize the contract by registering the initial admin participant
3. Set appropriate quality thresholds and other configuration variables

## Integration Examples

### Register a new farm product
```clarity
(contract-call? .agricultural-chain register-new-product 
    u12345 
    "Organic Apples" 
    "Washington State, USA" 
    u1000)
```

### Transfer product to a distributor
```clarity
(contract-call? .agricultural-chain transfer-product-ownership 
    u12345 
    'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK 
    "Transferring 500kg of Organic Apples to regional distributor")
```

### Record quality assessment
```clarity
(contract-call? .agricultural-chain update-quality-assessment 
    u12345 
    u85 
    "Quality inspection complete. Product meets organic certification standards.")
```

## Security Considerations

- Access control is implemented through principal-based authentication
- Input validation enforces data integrity
- Only the current custodian can transfer product ownership
- Contract admin has special privileges for participant management

## Dependencies

- Clarity language
- Stacks blockchain platform