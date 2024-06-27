# Create a new rancher2 Global Role Binding using group_principal_id

resource "rancher2_global_role_binding" "foo2" {
  name = var.name
  global_role_id = var.global_role_id
  group_principal_id = var.group_principal_id
}

