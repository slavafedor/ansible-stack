#!/usr/bin/env python3
"""
Custom Ansible filters for password lookup from vault
"""


def get_vault_password(vault_passwords, hostname, username, fallback_hostname=None):
    """
    Safely lookup password from vault structure

    Args:
        vault_passwords: The vault password dictionary
        hostname: The hostname or IP to lookup
        username: The username to lookup
        fallback_hostname: Alternative hostname to try if first lookup fails

    Returns:
        Password string or None if not found
    """
    # Try primary hostname lookup
    if hostname in vault_passwords:
        if username in vault_passwords[hostname]:
            return vault_passwords[hostname][username]

    # Try fallback hostname if provided
    if fallback_hostname and fallback_hostname in vault_passwords:
        if username in vault_passwords[fallback_hostname]:
            return vault_passwords[fallback_hostname][username]

    return None


def get_service_credential(vault_service_credentials, service, credential_type):
    """
    Lookup service credentials from vault

    Args:
        vault_service_credentials: Service credentials dictionary
        service: Service name (e.g., 'smtp', 'grafana')
        credential_type: Type of credential (e.g., 'username', 'password')

    Returns:
        Credential value or None if not found
    """
    if service in vault_service_credentials:
        if credential_type in vault_service_credentials[service]:
            return vault_service_credentials[service][credential_type]

        # Handle nested structure like smtp.gmail.username
        for subservice, creds in vault_service_credentials[service].items():
            if isinstance(creds, dict) and credential_type in creds:
                return creds[credential_type]

    return None


def safe_password_lookup(vault_data, host_info, username=None):
    """
    Comprehensive password lookup with multiple fallback strategies

    Args:
        vault_data: Complete vault data structure
        host_info: Dictionary with 'hostname', 'ansible_host', 'inventory_hostname'
        username: Username to lookup (optional, can be in host_info)

    Returns:
        Password or None
    """
    username = username or host_info.get("ansible_user", "root")

    # Get vault passwords section
    vault_passwords = vault_data.get("vault_passwords", {})
    vault_passwords_by_hostname = vault_data.get("vault_passwords_by_hostname", {})

    # Try different lookup strategies
    lookup_strategies = [
        # Strategy 1: ansible_host with username
        (host_info.get("ansible_host"), username),
        # Strategy 2: inventory_hostname with username
        (host_info.get("inventory_hostname"), username),
        # Strategy 3: hostname with username
        (host_info.get("hostname"), username),
    ]

    # Try IP/ansible_host based lookup first
    for hostname, user in lookup_strategies:
        if hostname:
            password = get_vault_password(vault_passwords, hostname, user)
            if password:
                return password

    # Try hostname-based lookup
    for hostname, user in lookup_strategies:
        if hostname:
            password = get_vault_password(vault_passwords_by_hostname, hostname, user)
            if password:
                return password

    return None


class FilterModule(object):
    """Ansible filter plugin"""

    def filters(self):
        return {
            "get_vault_password": get_vault_password,
            "get_service_credential": get_service_credential,
            "safe_password_lookup": safe_password_lookup,
        }
