IRSeC-scripts is a collection of security scripts and information used to defend a network of systems during a university incident response security competition. These scripts automate monitoring, log collection, and security controls to assist in active incident response scenarios.

**Disclaimer ⚠️**:
These scripts are provided for educational and competitive purposes only. Do not use them on production systems or networks without proper authorization. The author is not responsible for any misuse or damages.


<br>
<br>

# Directory

## Wazuh
- The wazuh folder contains all information and scripts pertaining to Wazuh.
- `agent_conf` contains the centralized agent configurations for the 'windows' and 'linux' agent groups. See [centralized agent documentation](https://documentation.wazuh.com/current/user-manual/reference/centralized-configuration.html) for more information on agent.conf file
- `setup` directory contains files and scripts for initial Wazuh setup (probably not needed as Wazuh is already installed on the competition network.

### Wazuh Configuration
- The Wazuh server (Dino Asteroid) will be primarily used for monitoring critical file/directory changes and account/machine logins (unless injects require more usage).
- There will be two agent groups: 'windows' and 'linux'. See the [Grouping Agents](https://documentation.wazuh.com/current/user-manual/agent/agent-management/grouping-agents.html) page for more information on agent groups.
- To setup the configurations, backups of original config files should be made and config files from this repository should be copied via SCP.

<br>
<br>

## Linux
- The Linux folder contains all information and scripts pertaining to Linux machines.
- `linux-cheatsheet.md` contains useful commands
### Scripts
**IMPORTANT** - run `export IRSEC_REPO_DIR=<irsec repository location>` if this repository is not cloned at $HOME/IRSeC-2025/ or clone it at the root of root user's home directory 
- `blue_team_configuration.sh` initializes a bash source configuration and any important and consistently used values as variables for other scripts to use
- `check_bash_integrity.sh` checks the integrity and vulnerability of the bash shell and any binaries
- `file_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious files
- `user_audit.sh` removes any non-default users (asks user to confirm before deleting)
- `user_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious users

<br>
<br>

# Windows
...
