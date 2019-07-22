#!/usr/bin/env bash
docker run -v /watch:/watch -v /mnt/windows:/mnt/windows --detach-keys "ctrl-@,d" -h vaporator --name vaporator --rm -it lowlandresearch/vaporator:live /bin/bash
