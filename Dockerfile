# 多阶段构建 - Strapi Production Dockerfile
# 阶段 1: 依赖安装和构建
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 启用 corepack 以支持 Yarn 4
RUN corepack enable && corepack prepare yarn@4.5.0 --activate

# 安装系统依赖
RUN apk update && apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# 复制 package.json 和 yarn.lock
COPY package.json yarn.lock ./
COPY lerna.json ./
COPY .yarnrc.yml ./

# 复制 Yarn 二进制文件和配置
COPY .yarn .yarn

# 复制所有包的 package.json（用于依赖解析）
COPY packages/*/package.json ./packages/
COPY packages/*/*/package.json ./packages/*/
COPY examples/*/package.json ./examples/
COPY examples/*/*/package.json ./examples/*/

# 设置 Yarn 环境变量（禁用交互式模式，用于 Docker 构建）
ENV YARN_ENABLE_IMMUTABLE_INSTALLS=false
ENV YARN_ENABLE_INLINE_BUILDS=false
ENV YARN_PREFER_INTERACTIVE=false

# 验证 Yarn 配置
RUN echo "=== Yarn Configuration ===" && \
    yarn --version && \
    echo "Yarn path from config:" && \
    (yarn config get yarnPath 2>/dev/null || echo "Using default yarn") && \
    echo "Yarnrc.yml content:" && \
    cat .yarnrc.yml

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
RUN apk update && apk add --no-cache \
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

