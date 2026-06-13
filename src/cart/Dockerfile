FROM python:3.12.13-alpine3.23 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

FROM python:3.12.13-alpine3.23 AS production
WORKDIR /app
# Crear un usuario/grupo no-root para ejecutar la aplicación 
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Copiar paquetes Python instalados desde el stage builder 
COPY --from=builder /usr/local/lib/python3.12/site-packages/ /usr/local/lib/python3.12/site-packages/
# Copiar scripts de consola (ej: uvicorn) instalados por pip 
COPY --from=builder /usr/local/bin/ /usr/local/bin/
# Copiar código de la app y asignar propiedad al usuario no-root 
COPY --chown=appuser:appgroup app/ ./app/
# Ejecutar el contenedor como usuario no-root 
USER appuser
ENV CART_PERSISTENCE_PROVIDER=in-memory \
    PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
