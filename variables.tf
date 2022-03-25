variable "rg-name" {
    type = string
    default = "rg-lab"
}

variable "available-zones" {
    type = list(string)
    default = [ "East US" ]
}