terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.114" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
  backend "local" {}
}

provider "azurerm" {
  features {}
  # we will pass subscription_id via -var
}