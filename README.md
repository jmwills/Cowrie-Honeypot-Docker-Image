# Cowrie Honeypot (Alpine Docker Image)

This repository builds a lightweight Docker image for running the [Cowrie](https://github.com/cowrie/cowrie) honeypot on Alpine Linux.

## Features

- Cowrie v2.1.0 preconfigured
- Small image size using Alpine base
- Drops root privileges and runs as a non-root user
- Ready for deployment with sensible defaults

## Usage

1. Copy your config and requirements into the `dist/` folder:
   - `cowrie.cfg`
   - `requirements.txt`

2. Build the image:

`docker build -t cowrie-alpine .docker run -d -p 2222:2222 --name cowrie cowrie-alpine`
