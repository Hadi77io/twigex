# syntax=docker/dockerfile:1
# Multi-stage build for Twigex 0.15.0 (upstream ships a package-only Dockerfile
# that expects prebuilt ./twigex + frontend/dist). This one builds both stages.

FROM node:22-bookworm-slim AS frontend
WORKDIR /src/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

FROM golang:1.26-bookworm AS backend
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -trimpath -ldflags '-s -w -X github.com/twigex/twigex/model.Version=0.15.0' -o /out/twigex .

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata media-types \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=backend /out/twigex ./twigex
COPY --from=frontend /src/frontend/dist ./frontend/dist
COPY templates ./templates
COPY i18n ./i18n
COPY LICENSE ./LICENSE
EXPOSE 3000
CMD ["./twigex", "start"]
