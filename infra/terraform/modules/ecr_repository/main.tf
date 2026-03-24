resource "aws_ecr_repository" "this" {
  name                 = var.name
  force_delete         = var.force_delete
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}