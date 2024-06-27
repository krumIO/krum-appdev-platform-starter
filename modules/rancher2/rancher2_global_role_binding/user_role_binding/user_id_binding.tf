# Create a new rancher2 Global Role Binding using user_id
resource "rancher2_global_role_binding" "foo" {
  name = var.name
  global_role_id = var.global_role_id
  user_id = var.user_id
}
