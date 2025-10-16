IRSeC-scripts is a collection of security scripts and information used to defend a network of systems during a university incident response security competition. These scripts automate monitoring, log collection, and security controls to assist in active incident response scenarios.

**Disclaimer ⚠️**:
These scripts are provided for educational and competitive purposes only. Do not use them on production systems or networks without proper authorization. The author is not responsible for any misuse or damages.

# Directory

## Ansible
- The Ansible folder contains all information and scripts pertaining to Ansible automation

### General 
- `inventory/net.yaml` contains the an inventory file for every host on the network

### Scripts
- `auth_setup.sh` sets up SSH authentication for Ansible managed nodes

## Linux
- The Linux folder contains all information and scripts pertaining to Linux machines.
- `linux-cheatsheet.md` contains useful commands
### Scripts
- `blue_team_configuration.sh` initializes a bash source configuration and any important and consistently used values as variables for other scripts to use
- `check_bash_integrity.sh` checks the integrity and vulnerability of the bash shell and any binaries
- `file_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious files
- `user_audit.sh` removes any non-default users (asks user to confirm before deleting)
- `user_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious users

# Windows
...