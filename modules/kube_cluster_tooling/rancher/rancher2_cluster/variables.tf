// Variables
variable "name" {
  type = string
}

variable "rke2_k3s_version" {
  type = string
}

variable "rancher_api_url" {
  description = "The URL of the Rancher server"
}

variable "token_key" {
  type = string
}