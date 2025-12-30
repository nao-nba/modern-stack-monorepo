# フロントエンド（Next.js）用
resource "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
}

# バックエンド（FastAPI）用
resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
}


# lifecycle policy
resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Delete old images more than 5 to keep the storage cost low and maintain clean repository state."
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Delete old images more than 5 to keep the storage cost low and maintain clean repository state."
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}