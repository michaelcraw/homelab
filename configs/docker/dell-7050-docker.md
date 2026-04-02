# Dell 7050 Docker Containers

## Open WebUI (AI Chat Interface)
docker run -d \
  --name open-webui \
  --network host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

## Nginx Video Site
docker run -d \
  --name video-site \
  -p 9090:80 \
  -v /home/michael/video-site:/usr/share/nginx/html:ro \
  --restart unless-stopped \
  nginx

## Cowrie SSH Honeypot
docker run -d \
  --name cowrie \
  -p 2222:2222/tcp \
  -v cowrie-logs:/cowrie/var/log/cowrie \
  --restart unless-stopped \
  cowrie/cowrie:latest
