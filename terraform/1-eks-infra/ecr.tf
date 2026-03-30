locals {
  ecr_services = toset(["frontend", "api-server", "backend-worker"])
}

resource "aws_ecr_repository" "this" {
  for_each             = local.ecr_services
  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  # Scan on push — catches known CVEs immediately at build time.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# Keep the last 10 images per repo; expire everything older.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
