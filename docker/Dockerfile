FROM node:23.4-bookworm-slim
LABEL maintainer="GWI Platform Team"

# Install pnpm globally
RUN npm install -g pnpm@9.15.0

# Create app directory
WORKDIR /platform2-crosstabs

# Copy app files
COPY .npmrc /platform2-crosstabs/.npmrc
COPY .prettierrc /platform2-crosstabs/.prettierrc
COPY .prettierignore /platform2-crosstabs/.prettierignore
COPY pnpm-lock.yaml /platform2-crosstabs/pnpm-lock.yaml
COPY package.json /platform2-crosstabs/package.json

# Install app dependencies
RUN pnpm install
