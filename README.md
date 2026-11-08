# DayZ Dedicated Server Infrastructure

A self-hosted DayZ Dedicated Server infrastructure deployed on Ubuntu Linux, featuring mod configuration, AI integration, system monitoring, and centralized log management.

This project demonstrates practical Linux system administration and DevOps skills through the deployment, configuration, operation, and monitoring of a dedicated game server.

## Project Overview

The infrastructure consists of two virtual machines:

- **DayZ Server** — hosts the DayZ Dedicated Server and runs monitoring agents.
- **Monitoring Server** — collects, stores, and visualizes infrastructure metrics and application logs.

The environment is designed as a hands-on DevOps lab and portfolio project.

## Architecture

```text
                 DAYZ SERVER
                  Ubuntu Linux
                       |
          +------------+------------+
          |                         |
    DayZ Dedicated              Node Exporter
       Server                       |
          |                         |
     systemd service                |
          |                         |
          +------------+------------+
                       |
                 Grafana Alloy
                       |
                 Network Transfer
                       |
              MONITORING SERVER
                  Ubuntu Linux
                       |
          +------------+------------+
          |                         |
      Prometheus                   Loki
          |                         |
          +------------+------------+
                       |
                    Grafana
                       |
                Monitoring Dashboard
```

## Technology Stack

| Component | Technology |
|---|---|
| Operating System | Ubuntu Linux |
| Game Server | DayZ Dedicated Server |
| Service Management | systemd |
| Metrics Collection | Prometheus |
| System Metrics | Node Exporter |
| Log Collection | Grafana Alloy |
| Log Aggregation | Grafana Loki |
| Visualization | Grafana |
| Virtualization | Oracle VirtualBox |

## Infrastructure

The lab environment uses two virtual machines connected through a virtual network.

| Machine | Role |
|---|---|
| DayZ Server | Game server and metrics exporter |
| Monitoring Server | Prometheus, Loki and Grafana |

## DayZ Server

The DayZ Dedicated Server is deployed on Ubuntu Linux and managed through systemd.

The server environment includes:

- Dedicated server deployment and configuration.
- systemd service management.
- Mod configuration.
- AI integration.
- Server log management.
- Process monitoring.

## Monitoring

Prometheus and Node Exporter collect system and process metrics.

The monitoring setup includes:

- CPU utilization.
- Memory usage.
- Disk utilization.
- Network traffic.
- DayZ service availability.
- DayZ process CPU and memory usage.
- Process uptime.
- Process restart tracking.

## Centralized Logging

Grafana Alloy collects logs from the DayZ server and forwards them to Loki.

Collected log sources include:

- DayZ RPT logs.
- Script logs.
- Error logs.
- systemd journal logs.

Grafana provides centralized log exploration and filtering by log type.

## Grafana Dashboards

The monitoring dashboard provides a unified view of infrastructure health and DayZ server activity.

It includes:

- Server service status.
- Process status and uptime.
- CPU and memory utilization.
- Disk and network metrics.
- Process restart tracking.
- Error and warning statistics.
- Log volume visualization.
- Recent DayZ log entries.

## Skills Demonstrated

- Linux system administration.
- Linux service management with systemd.
- Server deployment and configuration.
- Prometheus monitoring.
- Grafana dashboard development.
- Centralized logging with Loki.
- Log collection with Grafana Alloy.
- Infrastructure troubleshooting.
- Virtual machine networking.

## Project Status

The DayZ server has been deployed and configured. The monitoring and centralized logging pipeline is operational.

This project is continuously evolving as part of a practical DevOps learning environment.

## Future Improvements

- Infrastructure deployment automation.
- Configuration management with Ansible.
- Backup and recovery automation.
- Improved alerting and notification workflows.
- Infrastructure documentation and deployment scripts.