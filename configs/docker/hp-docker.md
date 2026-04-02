# HP Compaq Docker Containers

## Syncthing (File Sync)
docker run -d \
  --name syncthing \
  --hostname hpNas \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 8384:8384 \
  -p 22000:22000/tcp \
  -p 22000:22000/udp \
  -p 21027:21027/udp \
  -v /home/michael/syncthing-config:/config \
  -v /mnt/nas/michael:/data \
  --restart unless-stopped \
  lscr.io/linuxserver/syncthing:latest
