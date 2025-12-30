# 1. まず本体を作る。ルール(ingress)は外だし。
resource "aws_security_group" "ecs_app" {
  name   = "${var.project_name}-ecs-app-sg"
  vpc_id = var.vpc_id

  # egress（外への通信）は共通
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. 「中身（3000番ルール）」を、本体(security_group_id)に紐付ける
resource "aws_security_group_rule" "ecs_frontend_ingress" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = var.alb_sg_id
  security_group_id        = aws_security_group.ecs_app.id # ここで本体を参照
}

# 3. 「中身（8000番ルール）」を、本体(security_group_id)に紐付ける
resource "aws_security_group_rule" "ecs_backend_ingress" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = var.alb_sg_id
  security_group_id        = aws_security_group.ecs_app.id # ここで本体を参照
}

# DB用
resource "aws_security_group" "ecs_db" {
  name   = "${var.project_name}-ecs-db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_app.id] # Appからの接続のみ許可
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# --- 3. Service Discovery (名前解決) ---
resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "mysql" {
  name = "db"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 60
      type = "A"
    }
  }
}

# --- 4. CloudWatch Log Groups ---
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 7
}


# --- 5. Task Definitions ---
# --------------------------------------------------------------------------------------------------
# 1. Frontend (Next.js)
# --------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024" # Next.jsのビルド/実行用に1GB確保
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_ecr_url
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        # ブラウザから叩くAPIのURL。ALBのDNS名を環境変数として注入
        { name = "NEXT_PUBLIC_API_URL", value = "http://${var.alb_dns_name}/api" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# --------------------------------------------------------------------------------------------------
# 2. Backend (FastAPI)
# --------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_ecr_url
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      # 1. 通常の環境変数（パスワード以外）
      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = "appdb" },
        { name = "DB_USER", value = "admin" }
      ],
      
      # 2. SSMから安全に取得する環境変数
      secrets = [
        {
          name      = "DB_PASSWORD",
          valueFrom = var.db_password_arn # SSMのARNを渡す
        }
      ]
    
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


# --- 6. ECS Services (実体の起動設定) ---

# Frontend Service
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_app.id]
  }
  load_balancer {
    target_group_arn = var.target_group_frontend_arn
    container_name   = "frontend"
    container_port   = 3000
  }
}

# Backend Service
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_app.id]
  }
  load_balancer {
    target_group_arn = var.target_group_backend_arn
    container_name   = "backend"
    container_port   = 8000
  }
}