# Create a new rancher2 User
# create random password
resource "random_password" "foo" {
  length = 16
  special = true
}

resource "rancher2_user" "foo" {
  name = var.name
  username = var.user_name
  password = "${random_password.foo.result}"
  enabled = true
}

# Create a new rancher2 global_role_binding for User
resource "rancher2_global_role_binding" "foo" {
  name = "foo"
  global_role_id = "user-base"
  user_id = rancher2_user.foo.id
}

# output the password and user id to a local file
resource "local_file" "foo" {
  content  = "User: ${rancher2_user.foo.username}\nUser ID: ${rancher2_user.foo.id}\nPassword: ${random_password.foo.result}"
  filename = "${path.root}/outputs/${var.user_name}-password.txt"
}
