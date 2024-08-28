# ELK Hardening

Automated ELK stack hardening for EEA4 - complementing adp-app-staging/ansible/roles/elk

## Pre-requisites

- developed and tested using Ansible 2.9.7
- a single-node ELK cluster deployed by adp-app-staging/ansible/roles/elk
- a TLS certificate and its private key under files/ named after the short hostname with extensions '.crt' and '.key' respectively

## Configuration

- *../../roles/elk/defaults/main.yml*
- *../../roles/elk/vars/main.yml*
- *vars/main.yml*

### Usage

`ansible-playbook harden.yml`

[//]:# (confluence:no)
