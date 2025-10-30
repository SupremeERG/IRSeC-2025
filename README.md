IRSeC-2025 is a collection of security scripts and information used to defend a network of systems during a university incident response security competition. These scripts automate monitoring, log collection, and security controls to assist in active incident response scenarios.

**Disclaimer ⚠️**:
These scripts are provided for educational and competitive purposes only. Do not use them on production systems or networks without proper authorization. The author is not responsible for any misuse or damages.

<br>

# Directory

## Wazuh
- The wazuh folder contains all information and scripts pertaining to Wazuh.
- `agent_conf` contains the centralized agent configurations for the 'windows' and 'linux' agent groups. See [centralized agent documentation](https://documentation.wazuh.com/current/user-manual/reference/centralized-configuration.html) for more information on agent.conf file
- `setup` directory contains files and scripts for initial Wazuh setup (probably not needed as Wazuh is already installed on the competition network.

### Configuration
- The Wazuh server (Dino Asteroid) will be primarily used for monitoring critical file/directory changes and account/machine logins (unless injects require more usage).
- There will be two agent groups: 'windows' and 'linux'. See the [Grouping Agents](https://documentation.wazuh.com/current/user-manual/agent/agent-management/grouping-agents.html) page for more information on agent groups.
- To setup the configurations, backups of original config files should be made and config files from this repository should be copied via SCP.

<br>
<br>

## MySQL

### Management
- run `CREATE USER 'example_user'@'%' IDENTIFIED BY 'password';` to create a user `example_user` with a password of `password` using the MySQL `caching_sha2_method`. Change `CREATE` TO `ALTER` to alter a user's password.
- run `mysql -u <user> -p` to login to <user> with a password.
- run `mysql_secure_installation` to secure MySQL with an interactive app by MySQL.
- query `SELECT user, host, authentication_string, plugin FROM mysql.user;` to view MySQL users
- query `SHOW GRANTS FOR '<user>'@'<host>';` to see user privileges
- query `DROP USER '<user>'@'%';` to remove a user

### Hardening
- run `mysql_secure_installation` to secure MySQL with an interactive app by MySQL.
- add `skip-name-resolve               # Avoids DNS spoofing` to `/etc/mysql/mysql.conf.d/mysqld.conf` (note in edit explains purpose of this)
- disable MySQL user shell access with `sudo usermod -s /usr/sbin/nologin mysql`

<br>
<br>

## Linux
- The Linux folder contains all information and scripts pertaining to Linux machines.
- `linux-cheatsheet.md` contains useful, commonly-needed information.
### Scripts
- `blue_team_configuration.sh` initializes a bash source configuration and any important and consistently used values as variables for other scripts to use
- `check_bash_integrity.sh` checks the integrity and vulnerability of the bash shell and any binaries
- `cron_audit.sh` shows each crontab file on the system as well as individual user crons
- `file_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious files
- `quarantine.sh` moves a file to /var/quarantine/<file> and prevents any file modification for further incident response investigation
- `user_audit.sh` removes any non-default users (asks user to confirm before deleting)
- `user_scanner.sh` reports (to blue_team_configuration.sh report file) any suspicious users

<br>
<br>

## Windows
...
