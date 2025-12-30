# RDS専用のサブネットを作る
resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.${count.index + 21}.0/24"
  availability_zone = var.az_names[count.index]
  tags              = { Name = "${var.project_name}-db-${var.az_names[count.index]}" }
}

# サブネットグループもここで作る
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-sng"
  subnet_ids = aws_subnet.db[*].id
  tags       = { Name = "${var.project_name}-db-sng" }
}



# 1. パスワードの自動生成（人間が管理しない運用）
resource "random_password" "db_password" {
  length  = 16
  special = false # 接続文字列のパースエラーを防ぐためまずはfalse
}

# 2. SSMパラメータストアへの格納
resource "aws_ssm_parameter" "db_password" {
  name  = "/app/db_password"
  type  = "SecureString"
  value = random_password.db_password.result
}



# 4. RDSインスタンス（最小構成・無料枠対象）
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdb"
  username               = "admin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true # 削除時にスナップショットを取らない設定
}

# 5. DB用セキュリティグループ
resource "aws_security_group" "db_sg" {
  name   = "${var.project_name}-db-sg"
  vpc_id = var.vpc_id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}