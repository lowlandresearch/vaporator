sudo docker container run --name vaporator -h vaporator -v /mnt/windows:/mnt/windows -v /watch:/watch -d --rm --detach-keys "ctrl-@,d" lowlandresearch/vaporator:live /usr/local/bin/mix run --no-halt
