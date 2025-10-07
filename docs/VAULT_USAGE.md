# Example: Update your inventory to use vault passwords

# First, copy your current inventory and update it

cp /home/slava/Projects/DevOps/local/inventory.ini /home/slava/Projects/DevOps/ansible-stack/ansible/inventory.ini

# Your inventory.ini should look like this

[webservers]
HPSRV ansible_host=192.168.1.127 ansible_user=slava
HP-Envy ansible_host=192.168.1.130 ansible_user=slava

[databases]
HPSRV ansible_host=192.168.1.127 ansible_user=slava

[RPIs]
RPi-Grow ansible_host=grow.local ansible_user=pi
RPi-ZW2-2 ansible_host=rpi-zw2-2.local ansible_user=bbu

[monitoring]
HP-Envy ansible_host=192.168.1.130 ansible_user=slava

[production:children]
webservers
databases
RPIs

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3

# The vault system will automatically look up passwords for each host

# based on the ansible_host and ansible_user values

# To get started

1. Initialize vault:

```bash
cd /home/slava/Projects/DevOps/ansible-stack/ansible
./vault-manage.sh init
```

2. Edit vault passwords:

```bash
./vault-manage.sh edit
```

3. Add your actual passwords in the vault file:

```bash
vault_passwords:
  "192.168.1.127":  # HPSRV
  slava: "actual_password_for_slava_on_hpsrv"
  "192.168.1.130":  # HP-Envy
  slava: "actual_password_for_slava_on_hp_envy"
  "grow.local":     # RPi-Grow
  pi: "actual_password_for_pi_user"
  "rpi-zw2-2.local": # RPi-ZW2-2
  bbu: "actual_password_for_bbu_user"
```

4. Test the setup:

```bash
./vault-manage.sh test
```

5. Use in playbooks:

```bash
ansible-playbook playbooks/prometheus/deploy.yml --vault-password-file=.vault_pass
```
