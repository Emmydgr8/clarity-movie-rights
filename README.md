# Movie Rights Management System

A blockchain-based system for managing movie rights and licenses built on the Stacks blockchain.

## Features

- Register new movies with associated rights
- Transfer movie rights between parties
- Track license expiration
- Check rights status
- Extend license durations
- Manage transferable vs non-transferable rights

## Contract Functions

- register-movie: Register a new movie with initial rights holder
- transfer-rights: Transfer movie rights to new holder
- get-movie-rights: Check current rights status of a movie
- are-rights-active: Check if movie rights are currently active
- extend-license: Extend the duration of existing movie rights

## Security

- Only contract owner can register new movies
- Rights can only be transferred by current rights holder
- Automatic tracking of license expiration
- Support for both transferable and non-transferable rights
