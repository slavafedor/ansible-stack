#!/bin/bash

# Default inventory file
INVENTORY_FILE="${1:-inventory.ini}"

# Check if inventory file exists
if [[ ! -f "$INVENTORY_FILE" ]]; then
	echo "Error: Inventory file '$INVENTORY_FILE' not found!"
	exit 1
fi

# Create base directory structure
echo "Creating base Ansible project structure..."
mkdir -p {roles,playbooks/templates,files}

# Parse inventory file for roles/tags
echo "Parsing inventory file for roles..."
# ROLES=$(grep -oP 'role=\K[^\s\]]+' "$INVENTORY_FILE" | sort -u)
ROLES=$(grep -oP 'roles\s*=\s*\K.*' ./inventory.ini | tr ',' '\n' | sed 's/ //g' | sort -u)

# Create role structure for each found role
for role in $ROLES; do
	echo "Creating role: $role"
	mkdir -p "roles/$role"/{tasks,handlers,templates,files,vars,defaults,meta}
	
	# Create default files for each role
	cat > "roles/$role/tasks/main.yml" << EOF
---
# Tasks for $role role
EOF

	cat > "roles/$role/handlers/main.yml" << EOF
---
# Handlers for $role role
EOF

	cat > "roles/$role/vars/main.yml" << EOF
---
# Variables for $role role
EOF

	cat > "roles/$role/defaults/main.yml" << EOF
---
# Default variables for $role role
EOF

	cat > "roles/$role/meta/main.yml" << EOF
---
dependencies: []
EOF
done

# Create sample ansible.cfg
cat > ansible.cfg << EOF
[defaults]
inventory = $INVENTORY_FILE
roles_path = roles
host_key_checking = False
retry_files_enabled = False
EOF

# Create sample demo.yml
cat > ./playbooks/demo.yml << EOF
---
- name: Demo playbook
  hosts: all
  become: yes
  vars:
    roles:
      - alerting
      - bb_dev
      - bb_hub

  tasks:
    - name: Sample task 1
      debug:
        msg: "This is a sample task in the demo playbook."

    - name: Sample task 2
      debug:
        var: roles
EOF

# Create "local" structure
echo "Creating 'local' structure..."
mkdir -p local/{files,inventory/{group_vars/{all,rpi},host_vars},ssh-keys/{ansible, root},vault}

echo "Project structure created successfully!"
tree -L 4 2>/dev/null || find . -type d -maxdepth 4