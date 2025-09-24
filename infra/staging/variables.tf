variable "subscription_id" {
  type = string
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "sit722-staging-shi"
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "project" {
  type    = string
  default = "sit722"
}

variable "env" {
  type    = string
  default = "staging"
}

# Existing ACR (permanent)
variable "shared_acr_name" {
  type = string
}

variable "shared_acr_rg" {
  type = string
}