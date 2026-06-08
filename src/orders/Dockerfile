FROM golang:1.24
<<<<<<< Updated upstream
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o orders .
EXPOSE 8080
CMD ["./orders"]
=======

WORKDIR /app

# Copiamos primero los archivos de dependencias para que Docker
# pueda reutilizar esta capa si cambia el codigo pero no las librerias
COPY go.mod go.sum ./
RUN go mod download

# Despues copiamos el resto del codigo fuente y compilamos el binario.
COPY . .
RUN go build -o orders .

EXPOSE 8080

CMD ["./orders"]
>>>>>>> Stashed changes
