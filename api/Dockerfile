# Multi-stage prod image. Build: docker build -t cukurmap-api .
# Çalışma dizini kökü api/ — compose build context'i de öyle ayarlı.

FROM node:22-slim AS build
WORKDIR /app
# openssl: prisma generate'in doğru engine target'ını (openssl 3.x) seçmesi için şart
RUN apt-get update -y && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci && npx prisma generate
COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:22-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-slim
ENV NODE_ENV=production
WORKDIR /app
# OpenSSL: Prisma engine'in runtime gereksinimi (slim image'da eksik olabilir)
RUN apt-get update -y && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*
COPY --from=deps /app/node_modules ./node_modules
# Generated Prisma client (deps stage'inde prisma CLI yok, build'den kopyalanır)
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=build /app/dist ./dist
COPY prisma ./prisma
COPY public ./public
COPY package.json ./
# uploads volume mount noktası (compose'ta named volume bağlanır)
RUN mkdir -p uploads && chown -R node:node /app
USER node
EXPOSE 3000
CMD ["node", "dist/main"]
