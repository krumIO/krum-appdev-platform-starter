// Minimal Terraform module that creates a cluster
resource "rancher2_cluster_v2" "foo" {
  //alias provider
  # provider = rancher2.admin
  name = var.name
  kubernetes_version = var.rke2_k3s_version

    # ignore changes
    lifecycle {
        ignore_changes = [
        kubernetes_version,
        ]
    }
}

# resource "local_file" "registration_token" {
#   content  = <<-EOF
# #!/bin/bash
# REGISTRATION_COMMAND="curl -fL ${var.rancher_api_url}/system-agent-install.sh | sh -s - --server ${var.rancher_api_url} --label 'cattle.io/os=linux' --token ${rancher2_cluster_v2.foo.cluster_registration_token[0].token} --etcd --controlplane --worker"
# MINION_ID="${var.salt_minion_id}"
# EOF
#   filename = "${path.root}/outputs/registration_command.env"
# }


# variable "salt_minion_id" {
#   description = "The id of the salt minion to run the command on"
#     default = ""
# }