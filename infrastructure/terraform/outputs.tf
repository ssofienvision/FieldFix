output "service_app_names" {
  value = [for k, v in module.services : v.app_name]
}

output "topics" {
  value = module.topics.topic_names
}
