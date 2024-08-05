This repo periodically pulls from the upstream Perplexica repo and pushes docker images to docker hub. If using reverse proxy, please refer to https://github.com/ItzCrazyKns/Perplexica/issues/241

The images are hosted on dockerhub
`https://hub.docker.com/r/rqi14/perplexica-backend`  
`https://hub.docker.com/r/rqi14/perplexica-app`

Docker images with three tags are pushed to dockerhub.
1. latest: the latest build of perplexica
2. x.x.x: the build of a specific version x.x.x
3. slim: the latest build of perplexica slimmed using https://github.com/slimtoolkit/slim

# How to use
This project assumes you use docker compose deployment, and searxng is served separately.

You need three files.
The first one is app.dockerfile, which should be placed together with your docker-compose.yaml file. 

You will also need your config.toml file (see sample.config.toml file in the master branch or the upstream master branch) 


`app.dockerfile`

```
# Step 1: Base it on some existing image
FROM rqi14/perplexica-app:slim

# Step 2: Read two args, NEXT_PUBLIC_WS_URL and NEXT_PUBLIC_API_URL
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

To include searxng in the docker compose file. Note for the setup below, the url of searxng in `config.toml` needs to be changed to `http://searxng:8080` or `http://127.0.0.1:4000`

```
services:
  searxng:
    image: docker.io/searxng/searxng:latest
    volumes:
      - ./searxng:/etc/searxng:rw
    ports:
      - 4000:8080
    networks:
      - default
    restart: unless-stopped

  perplexica-backend:
    image: rqi14/perplexica-backend:slim
    ports:
      - 3001:3001
    volumes:
      - ./backend-dbstore:/home/perplexica/data
      - ./config.toml:/home/perplexica/config.toml
    extra_hosts:
      - 'host.docker.internal:host-gateway'
    networks:
      - default
    restart: unless-stopped
    depends_on:
      - searxng


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

NB: NEXT_PUBLIC_API_URL and NEXT_PUBLIC_WS_URL have to be publicly accessible as they substitute urls in the frontend webpage.
