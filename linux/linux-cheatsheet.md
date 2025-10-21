

# Useful Commands
`crontab [-u <user>] -e` - edits crontabs for current user unless another is specified with the -u option

`kill` - terminate a running process

`lsof` - list open files

`ss -tulpan` - displays currently active TCP and UDP sockets, their process ID, and the local/remote IP addresses and ports of each

`sudo su` - switches user to root user

`tcpdump` - monitor real-time network traffic

`umask` - changes default file permissions (must be added to .profile file to persist)

`killall -u [username]` - kills all processes that are run by [username]

# Logging
Log data is typically kept in `/var` (variable)

- `/var/log/syslog` contains system log data excluding authentication logs
  
- `/var/log/auth.log` or `/var/log/secure` contains authentication log data for Debian or Red Hat respectively
  
- `/var/log/messages` contains non-critical and non-debug messages, including messages logged during boot-up (dmesg), auth, cron, daemon, etc.
  
- `/etc/rsyslog.conf` or `/etc/syslog.conf` contains the main rsyslogd/syslogd configuration. See manual page for rsyslog.conf or https://www.rsyslog.com/doc/

- log file rotation and cleaning can be accomplished with `logrotate`

# Services
- `systemctl list-units --no-pager -all` to show all systemd units
