FROM golang:1.24
<<<<<<< Updated upstream
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o catalog .
EXPOSE 8080
CMD ["./catalog"]
=======

WORKDIR /app

# Copiamos primero los archivos de dependencias para que Docker
# pueda reutilizar esta capa si cambia el código pero no las librerías.
COPY go.mod go.sum ./
RUN go mod download

# Después copiamos el resto del código fuente y compilamos el binario.
COPY . .
RUN go build -o catalog .

EXPOSE 8080

CMD ["./catalog"]
>>>>>>> Stashed changes
