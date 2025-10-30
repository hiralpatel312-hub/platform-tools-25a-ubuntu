variable "project_name" { 
    type = string 
}
variable "environment" {
     type = string
}
variable "cidr_block" { 
    type = string 
}
variable "region" { 
    type = string 
}
variable "azs" { 
    type = list(string) 
}

variable "vpc_cidr" {
  type        = string
}
