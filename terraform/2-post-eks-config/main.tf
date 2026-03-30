# This is a workaround for the fact that EKS/Terraform does not support setting a default storage class
# We need it set, but not until AFTER the cluster is running, so we have the separate post-eks configuration.

resource "kubernetes_storage_class_v1" "gp2_csi" {
  metadata {
    name = "gp2-csi"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type                        = "gp2"
    "csi.storage.k8s.io/fstype" = "xfs"
  }
}
