

# How to use
This project assumes you use docker compose deployment, and searxng is served separately.

You need three files.
The first one is app.dockerfile, which should be placed together with your docker-compose.yaml file. 

You will also need your config.toml file. 


`app.dockerfile`

```
# Step 1: Base it on some existing image
FROM rqi14/perplexica-app:slim

# Step 2: Read two args, NEXT_PUBLIC_WS_URL and NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_WS_URL
ARG NEXT_PUBLIC_API_URL

# Step 3: Perform substitutions within .js files using escaped URL arguments
# Use bash to handle the script for better variable handling

# Step 3: Perform substitutions within .js files
# Step 2: Define arguments
ARG NEXT_PUBLIC_WS_URL
ARG NEXT_PUBLIC_API_URL

# Step 3: Loop through .js files and replace placeholders
RUN find /home/perplexica/.next/static/chunks -type f -name '*.js' -exec sed -i 's|__NEXT_PUBLIC_WS_URL__|'"${NEXT_PUBLIC_WS_URL}"'|g; s|__NEXT_PUBLIC_API_URL__|'"${NEXT_PUBLIC_API_URL}"'|g' {} +
```

`docker-compose-yaml` 

```
services:
  perplexica-backend:
    image: rqi14/perplexica-backend:slim
    ports:
      - 3001:3001
    volumes:
      - /mnt/user/appdata/perplexica/backend-dbstore:/home/perplexica/data
      - ./config.toml:/home/perplexica/config.toml
    extra_hosts:
      - 'host.docker.internal:host-gateway'
    networks:
      - default
    restart: unless-stopped

  perplexica-frontend:
    build:
      context: .
      dockerfile: app.dockerfile
      args:
        - NEXT_PUBLIC_API_URL=http://<your-backend-exposed-address>:3001/api
        - NEXT_PUBLIC_WS_URL=ws://<your-backend-exposed-address>:3001
    depends_on:
      - perplexica-backend
    ports:
      - 3000:3000
    networks:
      - default
    restart: unless-stopped

```
