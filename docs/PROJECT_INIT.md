# Simple bash script to initiate new ansible role-based project

## Script file `structure_init.sh` usage

Usage:

```bash
./structure_init.sh [inventory_file.ini]
```

Example:

```bash
mkdir -p playbooks/new_ansible_prj
cd playbooks/new_ansible_prj
../../structure_init.sh ../../srv_inventory.ini
```

By default `structure_init.sh` will look for the `inventory.ini` file.

## Resulting folder structure

```bash
Project structure created successfully!
.
├── ansible.cfg
├── files
├── group_vars
├── host_vars
├── inventory.ini
├── playbooks
├── README.md
├── roles
│   ├── api
│   ├── data_lake
│   ├── sql_server
│   └── web
├── site.yml
├── structure_init.sh
└── templates
```

### Typical role folder structure

```bash
./roles/api/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── tasks
│   └── main.yml
├── templates
└── vars
    └── main.yml
```
