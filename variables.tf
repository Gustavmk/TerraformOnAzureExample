variable "rg-name" {
  type    = string
  default = "rg-lab"
}

variable "available-zones" {
  type    = list(string)
  default = ["East US"]
}

variable "kv-name" {
  type    = string
  default = "lab"
}

variable "stg-name" {
  type    = string
  default = "stglab"
}