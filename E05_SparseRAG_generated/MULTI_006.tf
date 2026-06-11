# AWS RDS
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "exampledb"
  username             = var.aws_username
  password             = var.aws_password
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West US"
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login          = var.azure_username
  administrator_login_password = var.azure_password
}

resource "azurerm_sql_database" "example" {
  name                = "example-sql-database"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
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
  name     = "example-sql-database"
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_password
}