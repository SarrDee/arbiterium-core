# Arbiterium Core

A universal arbitration layer smart contract for Web3 disputes, built with Clarity on the Stacks blockchain.

## Overview

Arbiterium Core provides a decentralized arbitration framework that enables any principal to open cases against another principal and have them resolved through democratic voting by registered arbitrators.

## Features

- **Arbitrator Management**: Owner can add and remove arbitrators from the system
- **Case Management**: Open disputes against any principal with transparent case tracking
- **Democratic Voting**: Arbitrators vote yes/no on cases with double-vote prevention
- **Automatic Resolution**: Cases close with automatic result calculation based on votes
- **Error Handling**: Comprehensive error codes for all failure scenarios

## Smart Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `init-owner` | Initialize contract owner (first caller) |
| `add-arbitrator` | Register a new arbitrator (owner-only) |
| `remove-arbitrator` | Remove an arbitrator (owner-only) |
| `open-case` | Create a new arbitration case |
| `vote` | Cast a vote on an open case (arbitrators-only) |
| `close-case` | Close a case and calculate results |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `case-result` | Get full case details by ID |
| `is-arbitrator` | Check if a principal is an active arbitrator |

## Error Codes

- `u13001` - ERR-NOT-ARBITRATOR
- `u13002` - ERR-CASE-NOT-FOUND
- `u13003` - ERR-ALREADY-VOTED
- `u13004` - ERR-CASE-CLOSED
- `u13005` - ERR-NOT-OPEN

## Installation

Deploy the contract to Stacks:

```bash
stx deploy contracts/arbiterium-core.clar
