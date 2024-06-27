# Create a new Rancher2 Cluster Role Template Binding
resource "rancher2_cluster_role_template_binding" "foo" {
  name = var.name
  cluster_id = var.cluster_id
  role_template_id = var.role_template_id
  user_id = var.user_id
}
