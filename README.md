*WORK IN PROGRESS: USE IF YOU WANT*
- This project is evolving as I work through setting everything up.

- The goal is to create a reproducable environment, before I take snapshots and backup. Basically the instructions on how to set things up in the first place, if I had to start from scratch. That way the scripts basically document everything as I go along with version history.

This repository is a set of script to help setup and build asterisk in a lxc container.

It was written for use on a Rocky 8 system, so the tooling and directory's may be different for your environment.


# Useful commands.

- Managing Containers.
```snapshot
curl -sSL https://raw.githubusercontent.com/cjemorton/build_asterisk/master/snapshot.sh | bash
```
- List all containers: (Run: ```lxc ls``` to get <container_name>)
```list
curl -sSL https://raw.githubusercontent.com/cjemorton/build_asterisk/master/snapshot.sh | bash -s -- <container_name> -l
```

# Useful URL's and resources.
- Download directory for asterisk.
```asterisk
http://downloads.asterisk.org/pub/telephony/asterisk/
```
