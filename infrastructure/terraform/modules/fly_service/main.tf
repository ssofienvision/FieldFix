variable "app_name" { type = string }
variable "image"    { type = string }
variable "env_map"  { type = map(string) }
variable "min_machines" { type = number, default = 1 }

resource "fly_app" "this" {
  name = var.app_name
}

resource "fly_machine" "this" {
  app    = fly_app.this.name
  count  = var.min_machines

  image  = var.image

  env = var.env_map

  services = [{
    ports = [{
      port     = 80
      handlers = ["http"]
    }]
    protocol = "tcp"
    internal_port = 3000
  }]
}

output "app_name" {
  value = fly_app.this.name
}
