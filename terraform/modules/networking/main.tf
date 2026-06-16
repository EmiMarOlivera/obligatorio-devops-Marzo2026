locals {
  tags = {
    Environment = var.environment
    Project     = "retailstore"
    ManagedBy   = "terraform"
  }
}

# -------------------------------------------------------------------
# VPC — red privada virtual que aísla todos los recursos del ambiente
# enable_dns_hostnames permite que las instancias/contenedores dentro
# de la VPC resuelvan nombres DNS internos de AWS.
# -------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-vpc" })
}

# -------------------------------------------------------------------
# Internet Gateway — puerta de salida de la VPC hacia internet
# Sin esto, ningún recurso puede comunicarse con el exterior.
# -------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-igw" })
}

# -------------------------------------------------------------------
# Subnets públicas — tienen ruta directa al Internet Gateway
# Los load balancers viven aquí. map_public_ip_on_launch = true
# asigna una IP pública automáticamente a cualquier recurso lanzado.
# -------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "retailstore-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  })
}

# -------------------------------------------------------------------
# Subnets privadas — sin ruta directa a internet
# Los contenedores ECS y la base de datos viven aquí.
# Solo pueden salir a internet a través del NAT Gateway.
# -------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.tags, {
    Name = "retailstore-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  })
}

# -------------------------------------------------------------------
# Elastic IPs para los NAT Gateways
# domain = "vpc" es el valor requerido desde 2023 (reemplaza a
# the deprecated "vpc" vs "standard" distinction).
# -------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  domain = "vpc"

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-nat-eip-${count.index + 1}" })

  depends_on = [aws_internet_gateway.main]
}

# -------------------------------------------------------------------
# NAT Gateways — uno por AZ (alta disponibilidad)
# Permiten que los contenedores en subnets privadas descarguen
# imágenes de Docker, llamen APIs externas, etc., sin exponerse.
# Viven en las subnets PÚBLICAS porque necesitan acceso a internet.
# -------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.main]
}

# -------------------------------------------------------------------
# Route table pública — una sola para todas las subnets públicas
# La ruta 0.0.0.0/0 → IGW envía todo el tráfico externo al gateway.
# -------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------------------------
# Route tables privadas — una por AZ, apuntan al NAT Gateway de la misma AZ
# Tener una route table por AZ garantiza que si una AZ falla,
# el tráfico de la otra AZ no se interrumpe.
# -------------------------------------------------------------------
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, { Name = "retailstore-${var.environment}-private-rt-${count.index + 1}" })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}