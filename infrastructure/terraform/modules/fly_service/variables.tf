variable "app_name" { type = string }
variable "image"    { type = string }
variable "env_map"  { type = map(string) }
variable "min_machines" { type = number, default = 1 }
