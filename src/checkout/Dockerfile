FROM node:22.22.3-alpine3.23 AS builder
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install

COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src/ ./src/
RUN yarn build

FROM node:22.22.3-alpine3.23 AS production
WORKDIR /app
# Crear usuario no root // propuesto por la ia
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY package.json yarn.lock ./
RUN yarn install --production && yarn cache clean
COPY --from=builder /app/dist ./dist
# Cambiar propiedad de archivos y cambiar a usuario no root
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 8080
CMD ["node", "dist/main.js"]