*WORK IN PROGRESS: USE IF YOU WANT*

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
