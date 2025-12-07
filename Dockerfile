# 多阶段构建 - Strapi Production Dockerfile
# 阶段 1: 依赖安装和构建
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# 复制 package.json 和 yarn.lock
COPY package.json yarn.lock ./
COPY lerna.json ./

# 复制所有包的 package.json（用于依赖解析）
COPY packages/*/package.json ./packages/
COPY packages/*/*/package.json ./packages/*/
COPY examples/*/package.json ./examples/
COPY examples/*/*/package.json ./examples/*/

# 安装依赖（使用 production 模式）
RUN yarn install --frozen-lockfile --production=false

# 复制所有源代码
COPY . .

# 构建项目
RUN yarn build

# 阶段 2: Production 运行时
FROM node:20-alpine AS production

# 设置工作目录
WORKDIR /app

# 安装运行时依赖
RUN apk add --no-cache \
    dumb-init \
    curl \
    ca-certificates

# 创建非 root 用户（使用固定 UID/GID 以便 K8s 挂载卷）
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001

# 从构建阶段复制必要的文件
COPY --from=builder --chown=strapi:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=strapi:nodejs /app/package.json ./
COPY --from=builder --chown=strapi:nodejs /app/packages ./packages
COPY --from=builder --chown=strapi:nodejs /app/dist ./dist

# 设置环境变量
ENV NODE_ENV=production
ENV STRAPI_DISABLE_EE=false

# 暴露端口
EXPOSE 1337

# 切换到非 root 用户
USER strapi

# 使用 dumb-init 作为 PID 1（处理信号）
ENTRYPOINT ["dumb-init", "--"]

# 启动命令
CMD ["node", "packages/core/strapi/dist/cli.js", "start"]

