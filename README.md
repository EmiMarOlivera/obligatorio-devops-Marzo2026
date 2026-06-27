# Retail Store - Sample App

Aplicación de e-commerce basada en microservicios. Permite explorar un catálogo de productos, gestionar un carrito de compras, realizar el checkout y consultar órdenes. Incluye un panel de administración para gestionar productos y ver órdenes.

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) 24+
- [Docker Compose](https://docs.docker.com/compose/install/) v2.20+

## Inicio rápido

```bash
docker compose up --build
```

| Servicio | URL                   |
|----------|-----------------------|
| Tienda   | http://localhost:8080 |
| Admin    | http://localhost:8081 |

Credenciales del admin por defecto: `admin` / `admin`

## Comandos útiles

```bash
# Detener los servicios
docker compose down

# Detener y eliminar volúmenes (resetear base de datos)
docker compose down -v

# Reconstruir un servicio específico
docker compose up --build <servicio>

# Ver logs de un servicio
docker compose logs -f <servicio>
```

---

## Arquitectura de microservicios

```
          ┌──────────────────────────────────────────────────┐
          │               Usuario / Navegador                │
          └────────────────────────┬─────────────────────────┘
                                   │ HTTP
          ┌────────────────────────▼─────────────────────────┐
          │                   UI  :8080                      │
          │            Node.js 22 / Express                  │
          └───────┬──────────┬──────────┬────────────┬───────┘
                  │          │          │            │  HTTP (proxy)
        ┌─────────▼────┐ ┌───▼─────┐ ┌──▼────────┐ ┌▼──────────┐
        │   Catalog    │ │  Cart   │ │ Checkout  │ │  Orders   │
        │    :8080     │ │  :8080  │ │  :8080    │ │  :8080    │
        │  Go / Gin    │ │ Python  │ │ NestJS/TS │ │ Go / Gin  │
        └──────┬───────┘ └────┬────┘ └─────┬─────┘ └─────┬─────┘
               │              │            │  HTTP        │
               │              │            └─────────────►│
               │              │     ┌───────────────┐     │
               │              │     │    Redis 7    │◄────┤
               │              │     └───────────────┘     │
               └──────────────┴───────────────────────────┘
                                          │
        ┌─────────────────────────────────▼──────────────────────┐
        │                      PostgreSQL 16                     │
        │          catalogdb     │    cartdb    │    orders      │
        └────────────────────────────────────────────────────────┘

          ┌──────────────────────────────────────────────────┐
          │                  Admin  :8081                    │
          │            Node.js 22 / Express                  │
          └────────────────────────┬─────────────────────────┘
                                   │ SQL directo
          ┌────────────────────────▼─────────────────────────┐
          │                  PostgreSQL 16                   │
          └──────────────────────────────────────────────────┘
```

### Flujo de comunicación

| Origen     | Destino    | Protocolo | Descripción                              |
|------------|------------|-----------|------------------------------------------|
| UI         | Catalog    | HTTP REST | Listar y consultar productos             |
| UI         | Cart       | HTTP REST | Agregar, quitar y consultar carrito      |
| UI         | Checkout   | HTTP REST | Iniciar y confirmar el proceso de pago   |
| UI         | Orders     | HTTP REST | Consultar historial de órdenes           |
| Checkout   | Orders     | HTTP REST | Crear orden al confirmar checkout        |
| Checkout   | Redis      | TCP       | Persistencia de sesión de checkout       |
| Catalog    | PostgreSQL | TCP       | Base de datos `catalogdb`                |
| Cart       | PostgreSQL | TCP       | Base de datos `cartdb`                   |
| Orders     | PostgreSQL | TCP       | Base de datos `orders`                   |
| Admin      | PostgreSQL | TCP       | Acceso directo a todas las bases         |

---

## Tecnologías por servicio

| Servicio     | Lenguaje       | Framework        | Runtime         | Persistencia      | Puerto externo |
|--------------|----------------|------------------|-----------------|-------------------|----------------|
| **ui**       | TypeScript     | Express          | Node.js 22      | —                 | 8080           |
| **catalog**  | Go 1.24        | Gin + GORM       | Alpine Linux    | PostgreSQL        | —              |
| **cart**     | Python 3.12    | FastAPI          | Python slim     | PostgreSQL        | —              |
| **checkout** | TypeScript     | NestJS           | Node.js 22      | Redis             | —              |
| **orders**   | Go 1.24        | Gin + GORM       | Alpine Linux    | PostgreSQL        | —              |
| **admin**    | TypeScript     | Express          | Node.js 22      | PostgreSQL        | 8081           |
| **db**       | —              | PostgreSQL 16    | —               | —                 | —              |
| **redis**    | —              | Redis 7          | Alpine Linux    | —                 | —              |

### Dependencias clave

| Servicio     | Dependencias destacadas                                               |
|--------------|-----------------------------------------------------------------------|
| **catalog**  | `gin-gonic/gin`, `gorm`, `go-gorm/postgres`, OpenTelemetry           |
| **cart**     | `FastAPI`, `Uvicorn`, `Pydantic`, `psycopg2`, Prometheus client       |
| **checkout** | `NestJS`, `ioredis`, `class-validator`, OpenTelemetry                 |
| **orders**   | `gin-gonic/gin`, `gorm`, `go-gorm/postgres`, Prometheus              |
| **ui**       | `express`, `http-proxy-middleware`                                    |
| **admin**    | `express`, `pg`, `jsonwebtoken`, `cookie-parser`                      |

---

## Variables de entorno

### UI
| Variable                        | Descripción                  | Default               |
|---------------------------------|------------------------------|-----------------------|
| `RETAIL_UI_ENDPOINTS_CATALOG`   | URL del servicio catalog     | `http://catalog:8080` |
| `RETAIL_UI_ENDPOINTS_CARTS`     | URL del servicio cart        | `http://carts:8080`   |
| `RETAIL_UI_ENDPOINTS_CHECKOUT`  | URL del servicio checkout    | `http://checkout:8080`|
| `RETAIL_UI_ENDPOINTS_ORDERS`    | URL del servicio orders      | `http://orders:8080`  |

### Catalog / Orders / Cart
| Variable                               | Descripción           | Default          |
|----------------------------------------|-----------------------|------------------|
| `RETAIL_CATALOG_PERSISTENCE_PROVIDER`  | Tipo de persistencia  | `postgres`       |
| `RETAIL_CATALOG_PERSISTENCE_ENDPOINT`  | Host:Puerto de la DB  | `db:5432`        |
| `DB_PASSWORD`                          | Contraseña PostgreSQL | `retailpassword` |

### Checkout
| Variable                                   | Descripción              | Default               |
|--------------------------------------------|--------------------------|------------------------|
| `RETAIL_CHECKOUT_PERSISTENCE_PROVIDER`     | Tipo de persistencia     | `redis`               |
| `RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL`    | URL de Redis             | `redis://redis:6379`  |
| `RETAIL_CHECKOUT_ENDPOINTS_ORDERS`         | URL del servicio orders  | `http://orders:8080`  |

### Admin
| Variable            | Descripción                | Default                   |
|---------------------|----------------------------|---------------------------|
| `ADMIN_USERNAME`    | Usuario administrador      | `admin`                   |
| `ADMIN_PASSWORD`    | Contraseña administrador   | `admin`                   |
| `ADMIN_JWT_SECRET`  | Secreto para tokens JWT    | `change-me-in-production` |

---

## Estructura del repositorio

```
app/
├── docker-compose.yml
├── init-db.sql
└── src/
    ├── catalog/        # Go - Catálogo de productos
    ├── cart/           # Python - Carrito de compras
    ├── checkout/       # TypeScript/NestJS - Proceso de pago
    ├── orders/         # Go - Gestión de órdenes
    ├── ui/             # TypeScript/Express - Frontend
    └── admin/          # TypeScript/Express - Panel de administración

terraform/
├── bootstrap/          # Crea el bucket S3 y tabla DynamoDB para el estado remoto (se ejecuta una sola vez)
├── modules/
│   ├── networking/     # VPC, subnets públicas y privadas, Internet Gateway, NAT Gateways
│   ├── ecr/            # Repositorios de imágenes Docker por microservicio
│   ├── ecs/            # Cluster ECS con capacidad FARGATE y FARGATE_SPOT
│   ├── ecs_service/    # ALB, Target Group, Task Definition y ECS Service por microservicio
│   └── observability/  # SNS, Lambda, CloudWatch Alarms y Dashboard (ver sección abajo)
└── environments/
    ├── dev/            # Ambiente de desarrollo    — CIDR 10.0.0.0/16
    ├── staging/        # Ambiente de staging       — CIDR 10.1.0.0/16
    └── prod/           # Ambiente de producción    — CIDR 10.2.0.0/16
```

---

## Pipelines CI/CD

El repositorio tiene dos pipelines automáticos definidos en `.github/workflows/`.

### Pipeline de aplicación — `app.yml`

Se dispara automáticamente cuando hay cambios en `src/` en las ramas `main`, `staging` o `dev`. También se puede ejecutar manualmente eligiendo el ambiente.

```
┌─────────────────┐
│ Secrets Scan    │  Gitleaks detecta contraseñas o tokens expuestos en el código
│ (Gitleaks)      │
└────────┬────────┘
         │
    ┌────┴────────────────────────┐
    ▼                             ▼
┌──────────────┐        ┌─────────────────────┐
│ Code Scan    │        │ SCA Scan            │  Ambos corren en paralelo
│ (Semgrep)    │        │ (Trivy filesystem)  │
│ SAST: busca  │        │ Analiza go.mod,     │
│ bugs de      │        │ requirements.txt y  │
│ seguridad    │        │ package.json antes  │
│ en el código │        │ del build           │
└──────┬───────┘        └──────────┬──────────┘
       └──────────┬────────────────┘
                  ▼
    ┌─────────────────────────┐
    │ Build & Push to ECR     │  Construye la imagen Docker de cada servicio
    │ (7 servicios en matrix) │  y la sube al registro privado en AWS
    └────────────┬────────────┘
                 ▼
    ┌─────────────────────────┐
    │ Image Scan (Trivy)      │  Escanea la imagen ya construida buscando CVEs
    │ (6 servicios en matrix) │  CRITICAL o HIGH. Si encuentra uno con fix
    │ exit-code: 1            │  disponible → el pipeline falla (quality gate)
    └────────────┬────────────┘
                 ▼
    ┌─────────────────────────┐
    │ Deploy to ECS           │  Despliega en el cluster ECS del ambiente
    │ (6 servicios)           │  correspondiente (dev / staging / prod)
    └────────────┬────────────┘
                 ▼
    ┌─────────────────────────┐
    │ Load Test (k6)          │  Prueba de carga sobre el servicio checkout
    └─────────────────────────┘
```

### Pipeline de infraestructura — `infra.yml`

Se dispara cuando hay cambios en `terraform/` o manualmente eligiendo el ambiente. Ejecuta `terraform plan` y `terraform apply` para crear o actualizar la infraestructura en AWS.

---

## Seguridad integrada (DevSecOps)

### Herramientas en el pipeline

| Herramienta | Tipo | Cuándo corre | Qué detecta |
|-------------|------|-------------|-------------|
| **Gitleaks** | Secret detection | Primer paso, siempre | Contraseñas, tokens y API keys en el código |
| **Semgrep** | SAST | Antes del build | Patrones inseguros en el código fuente |
| **Trivy (filesystem)** | SCA | Antes del build | CVEs en dependencias declaradas (`go.mod`, `requirements.txt`, `package.json`) |
| **Trivy (image)** | Image scan | Después del build | CVEs en la imagen Docker completa (OS + lenguaje) |

### Quality gate

El scan de imagen corre con `exit-code: 1` y `severity: CRITICAL,HIGH` e `ignore-unfixed: true`. Esto significa:

- Si Trivy encuentra una vulnerabilidad **CRITICAL o HIGH** que **tiene fix disponible** y **no está justificada** → el pipeline falla y no se despliega.
- Si la vulnerabilidad no tiene fix del vendor todavía (`ignore-unfixed: true`) → se ignora, porque no hay acción posible.
- Si está en `.trivyignore` con justificación técnica → se ignora como excepción documentada.

### Excepciones justificadas (`.trivyignore`)

Algunos CVEs no pueden corregirse por restricciones de dependencias de terceros. Están documentados con justificación técnica en `.trivyignore`:

| CVE | Servicio | Razón de la excepción |
|-----|---------|----------------------|
| CVE-2024-47874, CVE-2026-48818, CVE-2026-54283 | `cart` | `starlette` no puede actualizarse porque `prometheus-fastapi-instrumentator==7.0.0` exige `starlette<1.0.0` |
| CVE-2026-33671 | `ui`, `checkout` | `picomatch` anidada en `http-proxy-middleware` no puede sobreescribirse desde `package.json` |
| CVE-2026-5079 | `checkout` | `multer` es dependencia transitiva de NestJS — requeriría actualizar todo el framework |

---

## Infraestructura en AWS (Terraform)

### Prerrequisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado con credenciales válidas

```bash
aws configure   # ingresar Access Key, Secret Key y región (us-east-1)
```

### Paso 1 — Bootstrap (solo la primera vez)

Crea el bucket S3 y la tabla DynamoDB que almacenan el estado remoto de Terraform. Se ejecuta una única vez por equipo.

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # completar con el nombre del bucket elegido
terraform init
terraform apply
```

Una vez creado el bucket, reemplazar `<nombre-del-bucket>` en los archivos `terraform/environments/*/backend.tf` con el nombre real.

### Paso 2 — Inicializar y aplicar un ambiente

```bash
cd terraform/environments/dev   # o staging, o prod
terraform init
terraform apply
```

### Ambientes

| Ambiente | VPC CIDR     | Subnets públicas            | Subnets privadas            |
|----------|--------------|-----------------------------|------------------------------|
| dev      | 10.0.0.0/16  | 10.0.1.0/24, 10.0.2.0/24   | 10.0.3.0/24, 10.0.4.0/24   |
| staging  | 10.1.0.0/16  | 10.1.1.0/24, 10.1.2.0/24   | 10.1.3.0/24, 10.1.4.0/24   |
| prod     | 10.2.0.0/16  | 10.2.1.0/24, 10.2.2.0/24   | 10.2.3.0/24, 10.2.4.0/24   |

---

## Observabilidad y Serverless

El módulo `terraform/modules/observability/` implementa un sistema de alertas automáticas sobre el servicio `checkout`, que es el más crítico del negocio (procesamiento de pagos).

### Arquitectura

```
[ECS Fargate - checkout]
        │
        │  emite métricas automáticamente (CPU, memoria, errores HTTP)
        ▼
[CloudWatch] ── evalúa alarmas cada 5 minutos
        │
        │  cuando se supera el umbral
        ▼
[SNS Topic "retailstore-{env}-alerts"]
        │
        │  notifica a todos los suscriptores
        ▼
[Lambda "retailstore-{env}-alert-handler"]  ← serverless
        │
        │  ejecuta alert_handler.py y registra la alerta
        ▼
[CloudWatch Logs]
```

### Componentes

| Recurso | Tipo | Descripción |
|---|---|---|
| SNS Topic | `aws_sns_topic` | Canal de mensajería que conecta alarmas con Lambda |
| Lambda Function | `aws_lambda_function` | Función Python que procesa y loguea cada alerta. Se ejecuta solo cuando dispara una alarma — no hay servidor permanente |
| CloudWatch Alarm 1 | `aws_cloudwatch_metric_alarm` | CPU del servicio `checkout` supera el 70% por 10 minutos consecutivos |
| CloudWatch Alarm 2 | `aws_cloudwatch_metric_alarm` | Errores HTTP 5xx en el ALB del `checkout` superan 5 en 5 minutos |
| CloudWatch Dashboard | `aws_cloudwatch_dashboard` | Paneles de CPU, memoria, errores 5xx y estado de alarmas para los 6 servicios |

### Alarmas — condición de disparo y procedimiento de respuesta

#### Alarma 1 — CPU alta en checkout

| | |
|---|---|
| **Métrica** | `CPUUtilization` — `AWS/ECS` — servicio `checkout` |
| **Condición** | Promedio de CPU > 70% durante 2 períodos consecutivos de 5 minutos (10 minutos sostenido) |
| **Por qué este umbral** | Un pico corto de CPU es normal. 10 minutos sostenidos por encima del 70% indica un problema real de capacidad o un loop en el código |

**Procedimiento de respuesta:**
1. Ir al dashboard de CloudWatch y confirmar qué servicios están afectados
2. Revisar los logs del servicio en CloudWatch Logs (`/ecs/checkout`) buscando errores o comportamiento anómalo
3. Si el tráfico es legítimamente alto: escalar el `desired_count` del servicio en Terraform y hacer `apply`
4. Si hay un bug o loop: hacer rollback de la última imagen desplegada en ECR y redeploy via CI/CD

#### Alarma 2 — Errores 5xx en el ALB de checkout

| | |
|---|---|
| **Métrica** | `HTTPCode_Target_5XX_Count` — `AWS/ApplicationELB` — ALB del servicio `checkout` |
| **Condición** | Suma de errores 5xx > 5 en un período de 5 minutos |
| **Por qué este umbral** | Los errores 5xx son fallos del servidor que impactan directamente al usuario. Más de 5 en 5 minutos indica una degradación del servicio de pago |

**Procedimiento de respuesta:**
1. Revisar el estado de las tareas ECS del servicio en la consola de AWS (puede haber tasks en estado `STOPPED`)
2. Consultar los logs en CloudWatch Logs (`/ecs/checkout`) para identificar el error específico (stack trace, connection error, timeout)
3. Si las tasks están caídas: verificar que la imagen en ECR es válida y forzar un nuevo deploy
4. Si el error es de dependencia (base de datos, Redis): revisar el estado de esos servicios y sus logs

---

### Logs centralizados

Todos los servicios envían sus logs automáticamente a CloudWatch Logs mediante el driver `awslogs`. Cada servicio tiene su propio log group:

| Servicio | Log Group |
|---|---|
| ui | `/ecs/ui` |
| catalog | `/ecs/catalog` |
| cart | `/ecs/cart` |
| checkout | `/ecs/checkout` |
| orders | `/ecs/orders` |
| admin | `/ecs/admin` |

Para buscar y filtrar logs entre todos los servicios, usar **CloudWatch Logs Insights** desde la consola de AWS. Ejemplo de consulta para ver todos los errores:

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50
```

### Código de la función Lambda

El código está en `terraform/modules/observability/lambda/alert_handler.py`. Recibe el mensaje de SNS, identifica si la alarma disparó o se resolvió, y lo registra en CloudWatch Logs con el nivel de severidad correspondiente (`WARNING` para alarma activa, `INFO` para resuelta).

### Dashboard

Luego de ejecutar `terraform apply`, el output `dashboard_url` muestra la URL directa al dashboard en la consola de AWS.
