#!/usr/bin/env bash
docker run -v /watch:/watch -v /mnt/windows:/mnt/windows --detach-keys "ctrl-@,d" -h vaporator -it lowlandresearch/vaporator:live /bin/bash
