# 1. ECSタスク実行ロール（コンテナを動かすための権限）
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# 基本的な実行権限（AmazonECSTaskExecutionRolePolicy）をアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/todo-app"
  retention_in_days = 7 # 7日間保存（料金を抑えるため）
}

# 2. SSMからパスワードを読むための追加ポリシー
resource "aws_iam_role_policy" "ssm_read_policy" {
  name = "${var.project_name}-ssm-read-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "kms:Decrypt"]
      Resource = [var.db_password_ssm_arn] # RDSモジュールから渡す
    }]
  })
}