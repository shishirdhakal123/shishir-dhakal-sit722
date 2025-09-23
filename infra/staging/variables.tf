variable "subscription_id" { type = string }
variable "location"        { type = string  default = "australiaeast" }
variable "project"         { type = string  default = "sit722" }
variable "env"             { type = string  default = "staging" }
variable "shared_acr_name" { type = string }  # existing ACR (permanent)