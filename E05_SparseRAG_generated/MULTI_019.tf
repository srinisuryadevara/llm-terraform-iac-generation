# AWS RDS
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "exampledb"
  username             = var.aws_rds_username
  password             = var.aws_rds_password
  vpc_security_group_ids = [aws_security_group.example.id]
  publicly_accessible  = true
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 5432"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "West US"
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password
}

resource "azurerm_sql_database" "example" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
}

# GCP Cloud SQL
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = "us-central1"
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_database" "example" {
  name     = "exampledb"
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_sql_password
}