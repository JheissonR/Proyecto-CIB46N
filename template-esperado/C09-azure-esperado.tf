# C09 (esperado) - Web segura: Application Gateway con WAF + CDN
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c09"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-c09"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "appgw" {
  name                 = "subnet-appgw-c09"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_network_security_group" "appgw" {
  name                = "nsg-appgw-c09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-c09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "waf-migraiac-c09"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  custom_rules {
    name      = "rate-limit"
    priority  = 1
    rule_type = "RateLimitRule"
    action    = "Block"
    rate_limit_threshold = 2000
    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      match_values       = ["0.0.0.0/0"]
    }
  }
}

resource "azurerm_application_gateway" "main" {
  name                = "appgw-migraiac-c09"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.main.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
  }

  request_routing_rule {
    name                       = "routing-rule"
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
  }
}

resource "azurerm_storage_account" "static" {
  name                     = "migraiacstaticc09"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_cdn_profile" "main" {
  name                = "cdn-migraiac-c09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "main" {
  name                = "cdn-endpoint-c09"
  profile_name        = azurerm_cdn_profile.main.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  origin {
    name      = "static-origin"
    host_name = azurerm_storage_account.static.primary_web_host
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}
