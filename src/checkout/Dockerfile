FROM node:22.22.3-alpine3.23 AS builder
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock ./
RUN yarn install

COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src/ ./src/
RUN yarn build

FROM node:22.22.3-alpine3.23 AS production
WORKDIR /app
# Actualizar libcrypto3 y libssl3 para corregir CVE-2026-45447
RUN apk upgrade --no-cache libcrypto3 libssl3
# Crear usuario no root // propuesto por la ia
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./
# Cambiar propiedad de archivos y cambiar a usuario no root
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 8080
CMD ["node", "dist/main.js"]