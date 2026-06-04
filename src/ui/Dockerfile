# syntax=docker/dockerfile:1
# Activa BuildKit: build en paralelo, mejor cache (practica 10)

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Imagen oficial (practica 6), tag especifico (practica 7), sabor alpine liviano (practica 8)
FROM node:22-alpine AS builder

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo los manifiestos de dependencias primero (cambian menos que el codigo)
# Asi la capa de npm ci se cachea y no se re-ejecuta si solo cambio src/ (practica 1 y 2)
COPY package*.json ./

# Instalamos TODAS las deps (incluye devDeps: typescript, @types/*) necesarias para compilar
# npm ci usa package-lock.json para installs reproducibles
RUN npm ci

# Copiamos el resto de archivos necesarios para compilar (mas frecuentes, van despues) (practica 1 y 2)
COPY tsconfig.json ./
COPY src/ ./src/
COPY public/ ./public/

# Compilamos TypeScript → genera la carpeta dist/
RUN npm run build

# ── Stage 2: production ───────────────────────────────────────────────────────
# Nueva imagen limpia: el compilador TypeScript y devDeps NUNCA llegan aqui (practica 11)
FROM node:22-alpine AS production

WORKDIR /app

COPY package*.json ./

# Instalamos solo dependencias de produccion (sin typescript, sin @types) (practica 4)
# Limpiamos la cache de npm en el mismo RUN para que no quede en ninguna capa (practica 3 y 5)
RUN npm ci --only=production && npm cache clean --force

# Copiamos unicamente el resultado compilado del stage builder (practica 2 y 11)
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

# Creamos usuario y grupo sin privilegios para no correr el proceso como root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# A partir de aqui todo corre como appuser, no como root
USER appuser

# Variable de entorno para el puerto
ENV PORT=8080

# Documenta el puerto que expone el contenedor
EXPOSE 8080

# Comando de inicio: corre el JS compilado
CMD ["node", "dist/app.js"]
