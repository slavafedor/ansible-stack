#!/bin/bash
# Ansible Vault Management Script
# Provides easy commands for managing encrypted vault files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="$SCRIPT_DIR/vault"
VAULT_FILE="$VAULT_DIR/passwords.yml"
VAULT_PASS_FILE="$VAULT_DIR/.vault_pass"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if vault password file exists
check_vault_password() {
    if [[ ! -f "$VAULT_PASS_FILE" ]]; then
        print_error "Vault password file not found: $VAULT_PASS_FILE"
        print_info "Create one with: echo 'your_vault_password' > $VAULT_PASS_FILE"
        print_info "Make sure to set proper permissions: chmod 600 $VAULT_PASS_FILE"
        return 1
    fi
    return 0
}

# Initialize vault
init_vault() {
    print_status "Initializing Ansible Vault setup..."
    
    # Create vault password file if it doesn't exist
    if [[ ! -f "$VAULT_PASS_FILE" ]]; then
        print_info "Creating vault password file..."
        read -s -p "Enter vault password: " vault_password
        echo
        echo "$vault_password" > "$VAULT_PASS_FILE"
        chmod 600 "$VAULT_PASS_FILE"
        print_status "Vault password file created at $VAULT_PASS_FILE"
    fi
    
    # Encrypt the vault file if it's not already encrypted
    if [[ -f "$VAULT_FILE" ]] && ! ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE" > /dev/null 2>&1; then
        print_info "Encrypting vault file..."
        ansible-vault encrypt "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE"
        print_status "Vault file encrypted successfully"
    fi
    
    print_status "Vault initialization complete!"
}

# Edit vault file
edit_vault() {
    check_vault_password || return 1
    print_status "Opening vault file for editing..."
    ansible-vault edit "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE"
}

# View vault file
view_vault() {
    check_vault_password || return 1
    print_status "Viewing vault file contents..."
    ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE"
}

# Encrypt vault file
encrypt_vault() {
    check_vault_password || return 1
    if ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE" > /dev/null 2>&1; then
        print_warning "Vault file is already encrypted"
    else
        print_status "Encrypting vault file..."
        ansible-vault encrypt "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE"
        print_status "Vault file encrypted successfully"
    fi
}

# Decrypt vault file
decrypt_vault() {
    check_vault_password || return 1
    if ! ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE" > /dev/null 2>&1; then
        print_warning "Vault file is already decrypted or doesn't exist"
    else
        print_status "Decrypting vault file..."
        ansible-vault decrypt "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE"
        print_status "Vault file decrypted successfully"
        print_warning "Remember to encrypt it again when done!"
    fi
}

# Test vault access
test_vault() {
    check_vault_password || return 1
    print_status "Testing vault access..."
    
    if ansible-vault view "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE" > /dev/null 2>&1; then
        print_status "✓ Vault file can be accessed successfully"
        
        # Test playbook with vault
        print_info "Running vault test playbook..."
        cd "$SCRIPT_DIR" && ansible-playbook test-vault.yml --vault-password-file="$VAULT_PASS_FILE" --limit localhost
    else
        print_error "✗ Cannot access vault file"
        return 1
    fi
}

# Change vault password
change_password() {
    check_vault_password || return 1
    print_status "Changing vault password..."
    
    read -s -p "Enter new vault password: " new_password
    echo
    read -s -p "Confirm new vault password: " confirm_password
    echo
    
    if [[ "$new_password" != "$confirm_password" ]]; then
        print_error "Passwords don't match!"
        return 1
    fi
    
    # Rekey the vault file
    ansible-vault rekey "$VAULT_FILE" --vault-password-file="$VAULT_PASS_FILE" --new-vault-password-file=<(echo "$new_password")
    
    # Update password file
    echo "$new_password" > "$VAULT_PASS_FILE"
    chmod 600 "$VAULT_PASS_FILE"
    
    print_status "Vault password changed successfully"
}

# Show usage
usage() {
    echo "Ansible Vault Management Script"
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  init        Initialize vault setup (create password file and encrypt vault)"
    echo "  edit        Edit encrypted vault file"
    echo "  view        View encrypted vault file contents"
    echo "  encrypt     Encrypt vault file"
    echo "  decrypt     Decrypt vault file (temporary)"
    echo "  test        Test vault access and run test playbook"
    echo "  change-pass Change vault password"
    echo "  help        Show this help message"
    echo
    echo "Files:"
    echo "  Vault file:     $VAULT_FILE"
    echo "  Password file:  $VAULT_PASS_FILE"
}

# Main script logic
case "$1" in
    init)
        init_vault
        ;;
    edit)
        edit_vault
        ;;
    view)
        view_vault
        ;;
    encrypt)
        encrypt_vault
        ;;
    decrypt)
        decrypt_vault
        ;;
    test)
        test_vault
        ;;
    change-pass)
        change_password
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        usage
        exit 1
        ;;
esac
