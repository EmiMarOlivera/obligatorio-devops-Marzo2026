variable "environment" {
  description = "Nombre del ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR principal de la VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para las subnets públicas (una por AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para las subnets privadas (una por AZ)"
  type        = list(string)
}

variable "azs" {
  description = "Lista de Availability Zones a usar"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Si es true, crea un NAT Gateway por AZ para que las subnets privadas accedan a internet"
  type        = bool
  default     = true
}
