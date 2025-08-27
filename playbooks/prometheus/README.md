# Prometheus Monitoring Stack Playbook

## Overview
This playbook sets up a Docker-based monitoring stack—Prometheus, Alertmanager, and Grafana—on hosts in the `monitoring` inventory group. It dynamically builds target lists from your inventory and configures alerting and visualization.

## Directory Layout
- `deploy.yml` – main playbook.
- `vars/main.yml` – default variables (ports, alert rules, datasource, Docker image versions).
- `templates/` – Jinja2 templates for Prometheus, Alertmanager, Grafana, and Docker Compose.

## Prerequisites
- Target hosts must have Docker and Docker Compose installed.
- Inventory group `monitoring` containing the hosts to manage.
- Optional: supply `templates/.env.j2` and `Dashboard.json` for Grafana; the playbook expects these but they are not provided in this repository.

## Variables
Key variables defined in `vars/main.yml`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `prometheus_port` | `9090` | Prometheus web UI port |
| `alertmanager_port` | `9093` | Alertmanager web UI port |
| `grafana_port` | `3000` | Grafana web UI port |
| `docker_network_name` | `monnet` | Docker network for all services |
| `monitoring_groups` | `[webservers, databases, monitoring]` | Inventory groups to include in node list |
| `prometheus_auto_start` | `false` | Start Docker containers automatically |

## Running the playbook
```bash
ansible-playbook playbooks/prometheus/deploy.yml
```

If prometheus_auto_start is false, start the stack manually:

```bash
cd ~/prometheus-stack && docker-compose up -d
```

By default services will be reachable at:

    Prometheus: http://localhost:9090
    Alertmanager: http://localhost:9093
    Grafana: http://localhost:3000

## How it works

1. Creates `~/prometheus-stack` and subdirectories for data and targets.
1. Generates `node_list.json` from the specified inventory groups.
1. Renders configuration and Docker Compose files from Jinja2 templates.
1. Optionally starts or restarts the stack with Docker Compose.