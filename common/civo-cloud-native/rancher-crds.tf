// Add helm chart repos to rancher for lifecycle mangaement
module "rancher_repo_crd_module_argo" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = module.argo.helm_repo_url
  repo_name         = module.argo.helm_repo_name
}

module "rancher_repo_crd_module_kube_loadbalancer_traefik" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = module.kube_loadbalancer.helm_repo_url_traefik
  repo_name         = module.kube_loadbalancer.helm_repo_name_traefik
}

module "rancher_repo_crd_module_neuvector" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = "https://neuvector.github.io/neuvector-helm/"
  repo_name         = "neuvector"
}

module "rancher_repo_crd_module_sonatype" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = module.nexus.helm_repo_url
  repo_name         = module.nexus.helm_repo_name
}

module "rancher_repo_crd_module_bitnami" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = "https://charts.bitnami.com/bitnami"
  repo_name         = "bitnami"
}

module "rancher_repo_crd_module_rancher" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = module.rancher.helm_repo_url
  repo_name         = module.rancher.helm_repo_name
}

module "rancher_repo_crd_module_kube_loadbalancer_cert_manager" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = module.kube_loadbalancer.helm_repo_url_cert_manager
  repo_name         = module.kube_loadbalancer.helm_repo_name_cert_manager
}

module "rancher_repo_crd_module_coder" {
  source            = "../../modules/kube_cluster_tooling/rancher/cluster-repo-crd"
  rancher_installed = var.rancher_installed
  repo_url          = "https://helm.coder.com"
  repo_name         = "coder"
}
