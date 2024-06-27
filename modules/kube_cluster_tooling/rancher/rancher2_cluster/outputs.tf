// Outputs
output "cluster_id" {
  value = rancher2_cluster_v2.foo.id
}

output "cluster_name" {
  value = rancher2_cluster_v2.foo.name
}

// output registration command
output "registration_token" {
  value = rancher2_cluster_v2.foo.cluster_registration_token
}

output "join_command" {
  value = rancher2_cluster_v2.foo.cluster_registration_token[0].command
}