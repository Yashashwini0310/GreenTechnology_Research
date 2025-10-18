#!/bin/bash
# ===============================================================
# Script: build_push_container.sh
# Purpose: Build, tag, and push FastAPI microservice image to AWS ECR
# Author: Yashashwini Research Project (Week 5)
# ===============================================================

set -e

# -----------------------------
# Configurable variables
# -----------------------------
AWS_REGION="us-east-1"             # Change if needed
REPO_NAME="sust-microservice"      # Same as used in Terraform
IMAGE_TAG="v1"                     # You can version increment this
DOCKERFILE_PATH="services/app/Dockerfile"   # Adjust if moved
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

echo "🚀 Building & pushing Docker image for ${REPO_NAME}:${IMAGE_TAG}"

# -----------------------------
# Get AWS Account ID
# -----------------------------
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# -----------------------------
# Create ECR repo if it doesn't exist
# -----------------------------
aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION >/dev/null 2>&1 || {
  echo "🪣 Creating ECR repository: $REPO_NAME"
  aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION
}

# -----------------------------
# Login to ECR (always needed in new terminal)
# -----------------------------
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# -----------------------------
# Build image
# -----------------------------
echo "🏗️ Building image..."
cd "$PROJECT_ROOT"
docker build -t ${REPO_NAME}:${IMAGE_TAG} -f ${DOCKERFILE_PATH} .

# -----------------------------
# Tag and push image
# -----------------------------
FULL_URI=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
docker tag ${REPO_NAME}:${IMAGE_TAG} ${FULL_URI}

echo "📤 Pushing image to ECR..."
docker push ${FULL_URI}

# -----------------------------
# Confirm push
# -----------------------------
echo "✅ Image successfully pushed!"
echo "   Repository URI: ${FULL_URI}"

# Optional cleanup
# docker image rm ${REPO_NAME}:${IMAGE_TAG} ${FULL_URI} >/dev/null 2>&1 || true

#chmod +x scripts/build_push_container.sh