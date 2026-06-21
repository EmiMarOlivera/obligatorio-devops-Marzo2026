# Informe de Hallazgos — Testing y Seguridad

## Resumen ejecutivo

Este informe cubre los resultados obtenidos por las herramientas de testing y seguridad integradas en los pipelines de CI/CD del proyecto RetailStore. Documenta los hallazgos encontrados, las remediaciones aplicadas y las excepciones justificadas, dando cumplimiento a los puntos 4.4 y 5.5 del obligatorio.

---

## 1. Testing de carga y rendimiento (k6)

**Herramienta:** k6  
**Integración:** Job `testing` en `.github/workflows/app.yml`, ejecutado post-deploy contra el ambiente configurado en `vars.APP_URL`.

### Configuración

| Parámetro | Valor |
|-----------|-------|
| Usuarios virtuales (VUs) | 5 |
| Duración total | ~100 segundos (ramp-up 30s + sustain 60s + ramp-down 10s) |
| Endpoints evaluados | `/` (home), `/catalog` |

### Quality gates definidos

| Threshold | Condición de corte |
|-----------|--------------------|
| `http_req_failed` | `rate < 0.05` — menos del 5% de requests fallidas |
| `http_req_duration` | `p(95) < 2000` — el 95% de las requests responde en menos de 2 segundos |

Si alguno de estos umbrales no se cumple, el pipeline falla y bloquea el pipeline.

### Hallazgos

Los thresholds actúan como quality gate activo. La aplicación fue diseñada para responder en tiempos sub-segundo bajo carga moderada (5 VUs), por lo que los umbrales establecidos son conservadores y alcanzables en un ambiente con recursos mínimos.

### Recomendaciones

- Incrementar los VUs en staging/prod para simular carga real.
- Agregar el endpoint `/checkout` y `/orders` al script de carga.
- Configurar un stage adicional de spike test (pico repentino de usuarios) para validar resiliencia.

---

## 2. Análisis estático de código — SAST (Semgrep)

**Herramienta:** Semgrep  
**Integración:** Job `code-scan` en `.github/workflows/app.yml`.  
**Resultados subidos a:** GitHub Security → Code Scanning Alerts (formato SARIF).

### Configuración

```yaml
semgrep scan --config=auto --sarif --output=semgrep-results.sarif ./src
```

`--config=auto` activa el conjunto de reglas recomendado por Semgrep para los lenguajes detectados (Go, Python, TypeScript, JavaScript). El pipeline falla si Semgrep reporta findings con severidad ERROR.

### Hallazgos

Semgrep analiza el código fuente de los seis microservicios buscando patrones inseguros: inyección SQL, deserialización insegura, uso de funciones peligrosas, manejo incorrecto de errores, entre otros. Los resultados específicos de cada ejecución quedan visibles en la pestaña **Security → Code scanning** del repositorio.

### Recomendaciones

- Revisar periódicamente las alertas en GitHub Security para atender findings de severidad WARNING.
- Agregar reglas específicas para cada lenguaje (`p/golang`, `p/python`, `p/typescript`) además de `auto`.

---

## 3. Análisis de composición de software — SCA (Trivy filesystem)

**Herramienta:** Trivy (modo `fs`)  
**Integración:** Job `code-scan` en `.github/workflows/app.yml`.  
**Resultados subidos a:** GitHub Security → Code Scanning Alerts (formato SARIF).

### Configuración

```yaml
scan-type: fs
scan-ref: ./src
severity: CRITICAL,HIGH
exit-code: '1'
ignore-unfixed: true
```

Trivy analiza los archivos de dependencias de cada microservicio (`go.mod`, `package.json`, `requirements.txt`) buscando CVEs conocidos en la base de datos pública.

### Quality gate

El pipeline falla si se detecta alguna vulnerabilidad **CRITICAL o HIGH que tenga parche disponible**.

### Excepción justificada: `ignore-unfixed: true`

Las vulnerabilidades sin parche disponible (`unfixed`) quedan excluidas del quality gate. Justificación: bloquear el pipeline por CVEs sin solución publicada impediría deployar sin que el equipo pueda hacer nada al respecto. La decisión es aceptar temporalmente esos riesgos, manteniéndolos visibles en GitHub Security para su seguimiento.

### Hallazgos

Los CVEs detectados y su estado son visibles en la pestaña **Security → Code scanning** del repositorio. Las vulnerabilidades CRITICAL/HIGH con fix disponible bloquean el pipeline antes de que la imagen llegue al registro.

### Recomendaciones

- Revisar mensualmente los CVEs marcados como `unfixed` para detectar cuándo se publican parches.
- Actualizar las dependencias con CVEs bloqueantes en cuanto haya versión corregida disponible.

---

## 4. Escaneo de imágenes de contenedor (Trivy image)

**Herramienta:** Trivy (modo `image`)  
**Integración:** Paso `Trivy - scan imagen antes del push` dentro del job `build-and-push` en `.github/workflows/app.yml`.  
**Resultados subidos a:** GitHub Security → Code Scanning Alerts (formato SARIF).

### Flujo de seguridad implementado

```
docker build → Trivy scan (imagen local) → [FALLA si CRITICAL/HIGH] → docker push → ECR
```

El scan ocurre sobre la imagen **antes de publicarla** en ECR. Si hay vulnerabilidades bloqueantes, la imagen nunca llega al registro.

### Configuración

```yaml
image-ref: <imagen local recién construida>
severity: CRITICAL,HIGH
exit-code: '1'
ignore-unfixed: true
```

### Excepción justificada: `ignore-unfixed: true`

Misma justificación que en el SCA: CVEs sin parche disponible no se pueden remediar actualizando dependencias. Se aceptan con seguimiento continuo.

### Hallazgos

Los resultados específicos de cada imagen escaneada quedan registrados en GitHub Security. La configuración garantiza que ninguna imagen con vulnerabilidades críticas o altas parchables llegue al registro ECR ni se deploya en ECS.

### Recomendaciones

- Actualizar las imágenes base (`node:22-alpine`, `golang:1.24-alpine`, `python:3.12-slim`) periódicamente para reducir la superficie de ataque.
- Considerar el uso de imágenes distroless para los servicios en Go, eliminando la capa del sistema operativo.

---

## 5. Detección de secretos expuestos (Gitleaks)

**Herramienta:** Gitleaks v2  
**Integración:** Primer paso en `.github/workflows/app.yml` y en `.github/workflows/infra.yml`.

### Configuración

Gitleaks escanea el historial completo de Git en cada ejecución del pipeline, buscando tokens, contraseñas, API keys y connection strings en commits pasados y presentes.

### Hallazgos

Gitleaks no detectó secretos activos en el repositorio. El pipeline no fue bloqueado por esta herramienta.

### Remediación aplicada — credenciales hardcodeadas (PR #23)

En una etapa temprana del proyecto se detectó que el servicio `admin` contenía credenciales hardcodeadas en el código fuente:

- Usuario y contraseña de administrador
- Contraseña de base de datos PostgreSQL
- JWT secret con valor por defecto inseguro (`change-me-in-production`)

**Acción tomada:** Las credenciales fueron extraídas a variables de entorno en el PR #23 ("fix: move hardcoded credentials to environment variables"). Los valores sensibles se gestionan hoy mediante secretos de GitHub Actions (`secrets.*`) y variables de entorno en los contenedores ECS.

### Recomendaciones

- Agregar un archivo `.gitleaks.toml` para ignorar falsos positivos conocidos (ej: cadenas de ejemplo en documentación).
- Evaluar el uso de AWS Secrets Manager para rotar credenciales en producción sin necesidad de redeploys.

---

## 6. Resumen de remediaciones y excepciones

### Remediaciones aplicadas

| Hallazgo | Severidad | Acción | PR/Commit |
|----------|-----------|--------|-----------|
| Credenciales hardcodeadas en servicio `admin` | ALTA | Migradas a variables de entorno | PR #23 |
| Imagen escaneada después del push (imagen potencialmente insegura en ECR) | MEDIA | Scan movido antes del push | PR #64 |

### Excepciones aceptadas

| Excepción | Justificación | Mitigación |
|-----------|---------------|------------|
| CVEs sin parche disponible (`ignore-unfixed: true`) | No existe acción correctiva posible mientras no haya fix publicado | Seguimiento continuo en GitHub Security; revisión mensual |

---

*Generado para el Obligatorio DevOps — ORT Uruguay, Marzo 2026.*
