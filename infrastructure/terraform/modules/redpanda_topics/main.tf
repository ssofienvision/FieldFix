variable "topics" {
  type = list(string)
}

# Placeholder resources; replace with actual Redpanda provider resources as needed.
# This is a stub showing how you'd declare topics.
output "topic_names" {
  value = var.topics
}
