FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copiamos primero los archivos de dependencias para aprovechar la cache.
COPY go.mod go.sum ./
RUN go mod download

# Después copiamos el resto del código y compilamos el binario.
COPY . .
RUN go build -o orders .

FROM alpine:3.22

# Creamos un usuario/grupo no-root para ejecutar la app.
RUN addgroup -S app && adduser -S -G app app

WORKDIR /app

# Copiamos únicamente el binario compilado desde la etapa builder.
COPY --from=builder --chown=app:app /app/orders .

USER app

EXPOSE 8080

ENTRYPOINT ["./orders"]