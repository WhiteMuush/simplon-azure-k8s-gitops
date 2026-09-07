# Project brief

## Summary

A company wants to deploy a brand new infrastructure on Microsoft's cloud. To do so, it needs you to provision it from A to Z and to set up a solution to protect its data.

## Objectives

- Set up a file sharing server for the employees (Entra ID group). Some employees are on Windows, others on macOS and Linux.
- Set up a Kubernetes cluster, and a namespace whose resources are protected by a regular and remote backup.
- Deploy a SQL database (MySQL, MariaDB, PostgreSQL...) with data persistence in the cloud.
- Make Git the source of truth for the infrastructure deployment, and use an IaC tool with a remotely persisted state.
- Automate the infrastructure deployment with a CI/CD pipeline of your choice.

## Out of scope

- Multi-environment
- Observability
- Load balancing, HA...

## Bonus

- The SQL database is deployed with ArgoCD.
- No credentials (access key, password) are present in Git or in Kubernetes.
