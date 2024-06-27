## local exec
resource "null_resource" "join-rancher-salt-local-exec" {
  provisioner "local-exec" {
    
    command = "sudo salt --log-level=debug --module-executors='[direct_call]' '${var.salt_minion_id}' cmd.run '/bin/bash ${var.rancher_join_command}'"
  }
}

variable salt_minion_id {
  description = "The id of the salt minion to run the command on"
  default = ""
}

variable rancher_join_command {
  description = "The command to join the Rancher cluster"
  default = ""
}