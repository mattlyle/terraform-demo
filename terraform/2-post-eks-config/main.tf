# CSI-backed StorageClass — cluster default for any StatefulSet needing EBS
# (Concourse PostgreSQL, workers). XFS avoids the lost+found issue that blocks
# PostgreSQL initdb when the volume root is not empty.
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
