# syntax=docker/dockerfile:1
# Activa BuildKit: build en paralelo y mejor cache.

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Imagen oficial de Go, tag especifico y variante Alpine liviana.
FROM golang:1.24.5-alpine3.22 AS builder

WORKDIR /app

# gcc y musl-dev son necesarios para compilar go-sqlite3 (requiere CGO).
RUN apk add --no-cache gcc musl-dev

# Copiamos primero los manifiestos para aprovechar cache de dependencias.
COPY go.mod go.sum ./

# Descargamos dependencias antes de copiar el codigo fuente.
RUN go mod download

# Copiamos el resto del codigo.
COPY . .

# Compilamos el binario de catalog.
RUN go build -o catalog .

# ── Stage 2: production ───────────────────────────────────────────────────────
# Imagen limpia y liviana: no incluye toolchain de Go ni archivos de build.
FROM alpine:3.22 AS production

WORKDIR /app

# Copiamos solo el binario compilado desde el builder.
COPY --from=builder /app/catalog ./catalog

# Creamos usuario y grupo sin privilegios para no correr como root.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# A partir de aqui el proceso corre como appuser.
USER appuser

# Documenta el puerto que expone el contenedor.
EXPOSE 8080

# Comando de inicio.
CMD ["./catalog"]