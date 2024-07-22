FROM node:alpine

ENV NEXT_PUBLIC_WS_URL=__NEXT_PUBLIC_WS_URL__
ENV NEXT_PUBLIC_API_URL=__NEXT_PUBLIC_API_URL__

WORKDIR /home/perplexica

COPY ui /home/perplexica/

RUN yarn install
RUN yarn build

CMD ["yarn", "start"]
