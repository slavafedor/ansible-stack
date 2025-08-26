# Ansible Control Node with Docker Compose

This project sets up an Ansible control node using Docker Compose, based on Ubuntu with Python 3.

## Project Structure

```text
.
├── docker-compose.yml        # Docker Compose configuration
├── Dockerfile                # Custom Ansible control node image
├── ansible/                  # Ansible configuration and playbooks
│   ├── ansible.cfg           # Ansible configuration file
│   ├── inventory             # Inventory file for target hosts
│   └── site.yml              # Example playbook
└── ssh-keys/                 # Directory for SSH keys (mounted read-only)
```

## Features

- **Ubuntu 22.04** base image with Python 3
- **Ansible** and **ansible-core** pre-installed
- Essential tools: ssh, git, vim, nano, tree, jq
- Python packages: paramiko, PyYAML, jinja2, netaddr, boto3
- Persistent command history
- Optimized Ansible configuration
- SSH key mounting for secure connections

## Quick Start

### 1. Build and Start the Container

```bash
docker-compose up -d --build
```

### 2. Access the Ansible Control Node

```bash
docker-compose exec ansible-control bash
```

### 3. Set Up SSH Keys (Optional)

If you need to connect to remote hosts, place your SSH keys in the `ssh-keys/` directory:

```bash
# Copy your private key
cp ~/.ssh/id_rsa ./ssh-keys/
chmod 600 ./ssh-keys/id_rsa

# Copy your public key
cp ~/.ssh/id_rsa.pub ./ssh-keys/
```

### 4. Configure Your Inventory

Edit `ansible/inventory` to add your target hosts:

```ini
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ubuntu
web2 ansible_host=192.168.1.11 ansible_user=ubuntu

[databases]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu
```

### 5. Test Connectivity

```bash
# Inside the container
ansible all -m ping
```

### 6. Run Playbooks

```bash
# Run the example playbook
ansible-playbook site.yml

# Run with specific inventory
ansible-playbook -i inventory site.yml
```

## Volume Mounts

- `./ansible:/ansible` - Your playbooks, inventory, and Ansible configuration
- `./ssh-keys:/root/.ssh:ro` - SSH keys for connecting to target hosts (read-only)
- `ansible-history` - Persistent bash history (for example: `../local/ansible-history:/root/.bash_history`)

## Environment Variables

- `ANSIBLE_HOST_KEY_CHECKING=False` - Disable SSH host key checking
- `ANSIBLE_INVENTORY=/ansible/inventory` - Default inventory location
- `ANSIBLE_CONFIG=/ansible/ansible.cfg` - Ansible configuration file

## Useful Commands

```bash
# Build and start
docker-compose up -d --build

# Access the container
docker-compose exec ansible-control bash

# View logs
docker-compose logs ansible-control

# Stop and remove
docker-compose down

# Stop and remove with volumes
docker-compose down -v
```

## Customization

### Adding More Python Packages

Edit the `Dockerfile` and add packages to the pip install command:

```dockerfile
RUN pip3 install \
    ansible \
    ansible-core \
    # Add your packages here
    requests \
    kubernetes
```

### Modifying Ansible Configuration

Edit `ansible/ansible.cfg` to customize Ansible behavior according to your needs.

### Adding Ansible Collections

You can install additional Ansible collections inside the container:

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

## Security Notes

- SSH keys are mounted read-only
- Consider using SSH agent forwarding for better security
- The container runs as root by default; you can switch to the `ansible` user if needed
- Host key checking is disabled for convenience but can be enabled in production

## Troubleshooting

### SSH Connection Issues

1. Ensure SSH keys have correct permissions (600 for private keys)
2. Verify target hosts are accessible from the Docker network
3. Check SSH configuration in `ansible.cfg`

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# Fix ownership (run from host)
sudo chown -R $USER:$USER ./ansible ./ssh-keys
```

### Container Not Starting

Check the logs:

```bash
docker-compose logs ansible-control
```

## Examples

### Basic Inventory Management

```bash
# List all hosts
ansible all --list-hosts

# List hosts in a specific group
ansible webservers --list-hosts

# Get facts from all hosts
ansible all -m setup
```

### Ad-hoc Commands

```bash
# Check uptime
ansible all -m command -a "uptime"

# Install a package
ansible webservers -m apt -a "name=nginx state=present" --become

# Copy a file
ansible all -m copy -a "src=/local/file dest=/remote/file"
```
