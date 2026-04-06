FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js ./
COPY public/ public/
ARG CACHE_BUST=1
COPY decks/ decks/
EXPOSE 3000
USER node
CMD ["node", "server.js"]
