#====================#
# vpc
#====================#
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

#====================#
# IGW
#====================#
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

#====================#
# パブリックサブネット
#====================#
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24" # 10.0.1.0 と 10.0.2.0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

#====================#
# プライベートサブネット
#====================#
# App用
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24" # 10.0.11.0 と 10.0.12.0
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# DB用
resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block = "10.0.${count.index + 21}.0/24" # 10.0.21.0 と 10.0.22.0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${var.project_name}-db-${data.aws_availability_zones.available.names[count.index]}" }
}

# RDSを使うために必須のサブネットグループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-sng"
  subnet_ids = aws_subnet.db[*].id # DB用サブネットのIDを全部入れる
  tags       = { Name = "${var.project_name}-db-sng" }
}

#====================#
# NATゲートウェイ
#====================#
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

# 2. NAT Gateway本体 (Publicサブネットに置く)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # 1つ目のパブリックに配置
  tags          = { Name = "${var.project_name}-nat-gw" }
}

#====================#
# ルートテーブル
#====================#
# ルートテーブル（パブリック）
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# ルートテーブルの紐付け（パブリック）
resource "aws_route_table_association" "public" {
  count          = 2 
  
  # インデックス番号を指定して、作成したサブネットを1つずつ取り出す
  subnet_id      = aws_subnet.public[count.index].id
  
  route_table_id = aws_route_table.public.id
}

# ルートテーブル（プライベート）→ 0.0.0.0/0 を NAT GW へ
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}


# ルートテーブルの紐付け（プライベート）
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

