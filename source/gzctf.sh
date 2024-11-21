#!/bin/bash

apt update && apt install -y docker-compose
# 配置初始化参数
GZCTF_ADMIN_PASSWORD=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
XOR_KEY=$(openssl rand -base64 32)
PUBLIC_ENTRY="http://$(hostname -I | awk '{print $1}')"

# 输出生成的随机参数
echo "Generated GZCTF_ADMIN_PASSWORD: $GZCTF_ADMIN_PASSWORD"
echo "Generated POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "Generated XOR_KEY: $XOR_KEY"
echo "Generated PUBLIC_ENTRY: $PUBLIC_ENTRY"

# 创建 appsettings.json 文件
cat <<EOL > appsettings.json
{
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "Database": "Host=db:5432;Database=gzctf;Username=postgres;Password=${POSTGRES_PASSWORD}"
  },
  "EmailConfig": {
    "SenderAddress": "",
    "SenderName": "",
    "UserName": "",
    "Password": "",
    "Smtp": {
      "Host": "localhost",
      "Port": 587
    }
  },
  "XorKey": "${XOR_KEY}",
  "ContainerProvider": {
    "Type": "Docker",
    "PortMappingType": "Default",
    "EnableTrafficCapture": false,
    "PublicEntry": "${PUBLIC_ENTRY}",
    "DockerConfig": {
      "SwarmMode": false,
      "Uri": "unix:///var/run/docker.sock"
    }
  },
  "RequestLogging": false,
  "DisableRateLimit": true,
  "RegistryConfig": {
    "UserName": "",
    "Password": "",
    "ServerAddress": ""
  },
  "CaptchaConfig": {
    "Provider": "None",
    "SiteKey": "<Your SITE_KEY>",
    "SecretKey": "<Your SECRET_KEY>",
    "GoogleRecaptcha": {
      "VerifyAPIAddress": "https://www.recaptcha.net/recaptcha/api/siteverify",
      "RecaptchaThreshold": "0.5"
    }
  },
  "ForwardedOptions": {
    "ForwardedHeaders": 7,
    "ForwardLimit": 1,
    "TrustedNetworks": ["192.168.12.0/8"]
  }
}
EOL

# 创建 compose.yml 文件
cat <<EOL > compose.yml
services:
  gzctf:
    image: registry.cn-shanghai.aliyuncs.com/gztime/gzctf:develop
    restart: always
    environment:
      - "GZCTF_ADMIN_PASSWORD=${GZCTF_ADMIN_PASSWORD}"
      - "LC_ALL=zh_CN.UTF-8"
    ports:
      - "80:8080"
    volumes:
      - "./data/files:/app/files"
      - "./appsettings.json:/app/appsettings.json:ro"
      - "/var/run/docker.sock:/var/run/docker.sock"
    depends_on:
      - db

  db:
    image: postgres:alpine
    restart: always
    environment:
      - "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
    volumes:
      - "./data/db:/var/lib/postgresql/data"
EOL

# 启动 Docker Compose 服务
docker-compose -f compose.yml up -d

# 输出部署状态
echo "部署完成！"
echo "服务正在启动中..."
