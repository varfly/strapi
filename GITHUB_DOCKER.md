# GitHub Container Registry 构建和推送指南

本文档说明如何使用 GitHub Actions 自动构建 Strapi Docker 镜像并推送到 GitHub Container Registry (ghcr.io)。

## 📋 概述

GitHub Container Registry (ghcr.io) 是 GitHub 提供的容器镜像注册表，与 GitHub 仓库紧密集成。

## 🚀 自动构建

### 触发条件

Workflow 会在以下情况自动触发：

1. **推送到 main 分支** - 构建并推送 `latest` 标签
2. **创建 Git 标签** - 构建并推送版本标签（如 `v5.31.3`）
3. **手动触发** - 通过 GitHub Actions 界面手动运行

### 工作流文件

- **`docker-build.yml`** - 完整版本（支持多架构和 PR）

## 📦 镜像地址格式

镜像地址格式：`ghcr.io/OWNER/REPOSITORY:TAG`

例如：
- `ghcr.io/your-username/strapi:latest`
- `ghcr.io/your-username/strapi:5.31.3`
- `ghcr.io/your-username/strapi:main`

## 🔧 使用方法

### 1. 自动构建（推荐）

只需推送代码到 main 分支或创建标签：

```bash
# 推送到 main 分支，自动构建 latest 标签
git push origin main

# 创建版本标签并推送
git tag v5.31.3
git push origin v5.31.3
```

### 2. 手动触发

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **Build and Push Docker Image (Simple)**
4. 点击 **Run workflow**
5. 可选：输入自定义标签
6. 点击 **Run workflow** 按钮

### 3. 拉取镜像

```bash
# 登录 GitHub Container Registry（首次使用）
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 拉取镜像
docker pull ghcr.io/your-username/strapi:latest
```

## 🔐 权限配置

### 公开镜像

默认情况下，推送到 ghcr.io 的镜像是私有的。要设置为公开：

1. 进入 GitHub 仓库
2. 点击右侧 **Packages**
3. 找到你的镜像包
4. 点击 **Package settings**
5. 在 **Danger Zone** 中点击 **Change visibility**
6. 选择 **Public**

### 使用 GitHub Token

Workflow 使用 `GITHUB_TOKEN`（自动提供），无需额外配置。

## 📊 查看构建状态

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 查看工作流运行状态
4. 点击运行查看详细日志

## 🏷️ 标签策略

- **`latest`** - main 分支的最新构建
- **`5.31.3`** - 从 package.json 提取的版本号
- **`v5.31.3`** - Git 标签（如果存在）
- **`main`** - 分支名称（如果不是 main）

## 🔄 缓存优化

Workflow 使用 GitHub Actions 缓存来加速构建：

- **构建缓存** - 缓存 Docker 层
- **依赖缓存** - 缓存 node_modules

## 🐛 故障排除

### 构建失败

1. 检查 Actions 日志
2. 确认 Dockerfile 语法正确
3. 检查是否有足够的构建时间（大项目可能需要 20-30 分钟）

### 推送失败

1. 确认仓库有 `packages: write` 权限
2. 检查 `GITHUB_TOKEN` 是否有效
3. 确认镜像名称格式正确

### 权限问题

如果遇到权限错误：

1. 进入仓库 **Settings** > **Actions** > **General**
2. 确认 **Workflow permissions** 设置为：
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests

## 📝 示例：在 Kubernetes 中使用

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strapi
spec:
  template:
    spec:
      containers:
      - name: strapi
        image: ghcr.io/your-username/strapi:latest
        imagePullPolicy: Always
```

### 配置 ImagePullSecrets（私有镜像）

如果镜像是私有的，需要配置认证：

```bash
# 创建 GitHub Personal Access Token (PAT)
# 需要权限: read:packages

# 创建 Secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=strapi
```

在 Deployment 中添加：

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ghcr-secret
      containers:
      - name: strapi
        image: ghcr.io/your-username/strapi:latest
```

## 🎯 最佳实践

1. **使用语义化版本标签** - 便于版本管理
2. **定期更新基础镜像** - 保持安全性
3. **监控构建时间** - 优化 Dockerfile 以加快构建
4. **使用多阶段构建** - 减小镜像大小（已在 Dockerfile 中实现）
5. **设置镜像为公开** - 如果不需要私有访问

## 📚 相关资源

- [GitHub Container Registry 文档](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Buildx 文档](https://docs.docker.com/buildx/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

