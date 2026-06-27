# syntax=docker/dockerfile:1
# Activa BuildKit: build en paralelo y mejor cache.

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Imagen oficial de Go, tag especifico y variante Alpine liviana.
FROM golang:1.25-alpine3.22 AS builder

WORKDIR /app

# Copiamos primero los manifiestos para aprovechar cache de dependencias.
COPY go.mod go.sum ./

# Descargamos dependencias antes de copiar el codigo fuente.
RUN go mod download

# Copiamos el resto del codigo.
COPY . .

# Compilamos el binario de orders.
RUN go build -o orders .

# ── Stage 2: production ───────────────────────────────────────────────────────
# Imagen limpia y liviana: no incluye toolchain de Go ni archivos de build.
FROM alpine:3.22 AS production

WORKDIR /app

# Creamos usuario y grupo sin privilegios para no correr como root.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiamos solo el binario compilado desde el builder y lo dejamos a nombre del usuario no-root.
COPY --from=builder --chown=appuser:appgroup /app/orders ./orders

# A partir de aqui el proceso corre como appuser.
USER appuser

# Documenta el puerto que expone el contenedor.
EXPOSE 8080

# Comando de inicio.
CMD ["./orders"]