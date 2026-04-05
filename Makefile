# Makefile
.PHONY: help print-env git-push create-env help-dependencies install-dependencies run-training run-api create-example-input-from-schema clean lint format install-pre-commit pre-commit install-project test-project publish-project build-training-amd64 build-training-arm64 build-inference-amd64 build-inference-arm64 run-training-arm64 run-inference-arm64 stop-training stop-inference download-compose-images up down authenticate-aws create-bucket upload-data-to-bucket check-main-bucket show-latest-dataset-version create-ecr-training-repository create-ecr-inference-repository tag-training-image-amd64 tag-inference-image-amd64 push-training-image-amd64 push-inference-image-amd64 sagemaker-deploy-training sagemaker-register-model sagemaker-create-endpoint-config sagemaker-create-endpoint sagemaker-run-batch-transform pipeline-local-training pipeline-sagemaker-training pipeline-local-inference pipeline-sagemaker-inference

include .env
export $(shell sed 's/=.*//' .env)

MAKEFLAGS += --silent

GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m


PROJECT_DIR := $(PWD)
PROJECT_NAME := $(shell basename $(PROJECT_DIR))
SRC_DIR := src
API_DIR := api

VENV_PATH := $(PROJECT_DIR)/.venv

IMAGE_NAME := $(PROJECT_NAME)-image
CONTAINER_NAME := $(PROJECT_NAME)-container

AWS_REGION := $(AWS_REGION)
AWS_ACCOUNT_ID := $(AWS_ACCOUNT_ID)
AWS_ECR_TRAINING_REPOSITORY_NAME := $(PROJECT_NAME)-training-repo
AWS_ECR_INFERENCE_REPOSITORY_NAME := $(PROJECT_NAME)-inference-repo
AWS_ECR_TRAINING_REPOSITORY_URL := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(AWS_ECR_TRAINING_REPOSITORY_NAME)
AWS_ECR_INFERENCE_REPOSITORY_URL := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(AWS_ECR_INFERENCE_REPOSITORY_NAME)
AWS_MAIN_BUCKET_NAME := $(PROJECT_NAME)-$(AWS_REGION)-$(AWS_ACCOUNT_ID)
AWS_TRAINING_PREFIX := training
AWS_INFERENCE_PREFIX := inference

# ====================================================

help:  ## Show the list of available commands
	echo "All available commands:"
	grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  🔹 %-35s %s\n", $$1, $$2}'

print-env:  ## Print loaded environment variables
	echo "PROJECT_NAME=$(PROJECT_NAME)"
	echo "IMAGE_NAME=$(IMAGE_NAME)"
	echo "CONTAINER_NAME=$(CONTAINER_NAME)"
	echo "AWS_REGION=$(AWS_REGION)"
	echo "AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID)"
	echo "AWS_ECR_TRAINING_REPOSITORY_NAME=$(AWS_ECR_TRAINING_REPOSITORY_NAME)"
	echo "AWS_ECR_INFERENCE_REPOSITORY_NAME=$(AWS_ECR_INFERENCE_REPOSITORY_NAME)"
	echo "AWS_ECR_TRAINING_REPOSITORY_URL=$(AWS_ECR_TRAINING_REPOSITORY_URL)"
	echo "AWS_ECR_INFERENCE_REPOSITORY_URL=$(AWS_ECR_INFERENCE_REPOSITORY_URL)"
	echo "AWS_MAIN_BUCKET_NAME=$(AWS_MAIN_BUCKET_NAME)"
	echo "MLFLOW_TRACKING_URI=$(MLFLOW_TRACKING_URI)"
	echo "MLFLOW_VERSION=$(MLFLOW_VERSION)"

git-push:  # Push changes to Git repository
	git reset
	git add .
	git commit -m "[UPDATE] $$(date '+%Y-%m-%d %H:%M:%S')"
	git push


# ====================================================
#  Virtual Environment
# ====================================================

create-env:  ## Create uv virtual environment
	uv venv
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - uv virtual environment created successfully"
	echo "source .venv/bin/activate" > .envrc
	direnv allow
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Run the following command to install dependencies:"
	echo "  make install-dependencies"

help-dependencies:  ## Show the list of available commands for dependencies
	echo "$(BLUE)[INFO]$(NC) Add dependencies:"
	echo " uv add <library-name>"
	echo " uv add --dev <library-name>"
	echo "$(BLUE)[INFO]$(NC) Remove dependencies:"
	echo " uv remove <library-name>"
	echo " uv remove --dev <library-name>"

install-dependencies:  ## Install dependencies with latest versions
	uv lock --upgrade
	uv sync
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Dependencies installed successfully"


# ====================================================
#  Training & API
# ====================================================

run-training:  ## Run the training locally
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training locally...\n"
	python train.py
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Local training completed successfully"

run-api:  ## Run the API locally
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Running API locally...\n"
	uvicorn $(API_DIR).main:app --host 0.0.0.0 --port 8080

create-example-input-from-schema:  ## Create example input from schema
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating example input from schema..."
	python -m $(SRC_DIR).schema


# ====================================================
#  Cleaning & Formatting
# ====================================================

clean:  ## Remove temporary files
	find . -type d \( -name ".venv" -prune \) -o -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	if [ -d cache ]; then rm -rf cache; fi
	if [ -d output ]; then rm -rf output; fi
	if [ -d logs ]; then rm -rf logs; fi
	rm -f input/example_input.json
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Temporary files removed, cache/, input/data/processed/, output/model/ and logs/ cleared"

lint:  ## Check code quality with Ruff (without fixing)
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Checking code with Ruff..."
	ruff check $(SRC_DIR)
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Code checked with Ruff"

format:  ## Format Python code with Ruff (imports + formatting)
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Formatting code with Ruff..."
	ruff check $(SRC_DIR) --fix
	ruff format $(SRC_DIR)
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Code formatted with Ruff"


# ====================================================
#  Pre-commit
# ====================================================

install-pre-commit:  ## Install pre-commit, only if the project is a Git repository
	if [ -d ".git" ]; then \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Installing pre-commit..."; \
		uv add pre-commit && pre-commit install; \
		echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Pre-commit installed"; \
	else \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Not a Git repository, skipping pre-commit installation"; \
	fi

pre-commit:  ## Run pre-commit hooks
	pre-commit run --all-files


# ====================================================
#  Project
# ====================================================

install-project:  ## Install the project
	uv pip install -e .
	echo "$(GREEN)$(GREEN)[SUCCESS]$(NC)$(NC) Project installed successfully"

test-project: install-project  ## Test the project
	uv run pytest
	echo "$(GREEN)$(GREEN)[SUCCESS]$(NC)$(NC) Project tested successfully"

publish-project: install-project  ## Publish the project
	uv pip install --upgrade build
	uv build
	uv publish


# ====================================================
#  Docker
# ====================================================

# Build

build-training-amd64:  ## Build the training Docker image for amd64
	docker build --platform linux/amd64 -t $(IMAGE_NAME)-training-amd64 -f Dockerfile.training .
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker image built for amd64"

build-training-arm64:  ## Build the training Docker image for arm64
	docker build --platform linux/arm64 -t $(IMAGE_NAME)-training-arm64 -f Dockerfile.training .
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker image built for arm64"

build-inference-amd64:  ## Build the inference Docker image for amd64
	docker build --platform linux/amd64 -t $(IMAGE_NAME)-inference-amd64 -f Dockerfile.inference .
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Inference Docker image built for amd64"

build-inference-arm64:  ## Build the inference Docker image for arm64
	docker build --platform linux/arm64 -t $(IMAGE_NAME)-inference-arm64 -f Dockerfile.inference .
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Inference Docker image built for arm64"

# Run

run-training-arm64: build-training-arm64  ## Run the training Docker container for arm64
	docker run --platform linux/arm64 --rm \
		-e SM_CHANNEL_TRAINING=/opt/ml/input/data/training \
		-e SM_MODEL_DIR=/opt/ml/model \
		-e SM_OUTPUT_DIR=/opt/ml/output \
		-v $(PWD)/input/data/training:/opt/ml/input/data/training \
		-v $(PWD)/models:/opt/ml/model \
		-v $(PWD)/processing:/opt/ml/output \
		$(IMAGE_NAME)-training-arm64 \
		python /opt/ml/code/train
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker container executed"

run-inference-arm64: build-inference-arm64  ## Run the inference Docker container for arm64
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Running inference Docker container..."
	echo "🔗 http://localhost:8080/docs#/"
	docker run --rm -p 8080:8080 --name $(CONTAINER_NAME)-inference-arm64 $(IMAGE_NAME)-inference-arm64

# Stop

stop-training:  ## Stop the training Docker container running locally
	docker stop $(CONTAINER_NAME)-training-arm64 || true
	docker stop $(CONTAINER_NAME)-training-amd64 || true
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker containers (arm64 and amd64) stopped"

stop-inference:  ## Stop the inference Docker container running locally
	docker stop $(CONTAINER_NAME)-inference-arm64 || true
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Inference Docker container (arm64) stopped"


# ====================================================
#  Docker Compose
# ====================================================

download-compose-images:  ## Download the compose images
	docker pull minio/minio:latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - minio:latest image downloaded successfully\n"
	docker pull minio/mc:latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - minio/mc:latest image downloaded successfully\n"
	docker pull postgres:15
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - postgres:15 image downloaded successfully\n"
	docker pull ghcr.io/mlflow/mlflow:$(MLFLOW_VERSION)
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - mlflow:$(MLFLOW_VERSION) image downloaded successfully"

up:  ## Start the MLflow server
	docker compose --env-file .env -f compose.yaml up -d
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - MinIO should be running at http://localhost:9001..."
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - MLflow UI should be running at http://localhost:8089..."

down:  ## Stop the MLflow server
	docker compose --env-file .env -f compose.yaml down
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - MinIO and MLflow servers stopped"


# ====================================================
#  AWS IAM
# ====================================================

authenticate-aws:  ## Authenticate to AWS
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - AWS authenticated"


# ====================================================
#  AWS S3
# ====================================================

create-bucket:  ## Create the main AWS S3 bucket (if it doesn't exist)
	if aws s3 ls "s3://$(AWS_MAIN_BUCKET_NAME)" 2>/dev/null; then \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Bucket s3://$(AWS_MAIN_BUCKET_NAME) already exists in region $(AWS_REGION)"; \
	else \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating bucket s3://$(AWS_MAIN_BUCKET_NAME) in region $(AWS_REGION)..."; \
		aws s3 mb s3://$(AWS_MAIN_BUCKET_NAME) --region $(AWS_REGION); \
		echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Bucket s3://$(AWS_MAIN_BUCKET_NAME) created successfully in region $(AWS_REGION)"; \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/s3/buckets/$(AWS_MAIN_BUCKET_NAME)?region=$(AWS_REGION)&tab=objects" \
	fi

upload-data-to-bucket:  ## Upload the data to the AWS S3 bucket (timestamped + latest)
	timestamp=$$(date "+%Y-%m-%d-%H-%M-%S") && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Uploading dataset with timestamp: $$timestamp" && \
	aws s3 cp input/data/training/data.csv s3://$(AWS_MAIN_BUCKET_NAME)/data/training/$$timestamp/data.csv --region $(AWS_REGION) && \
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Data uploaded to s3://$(AWS_MAIN_BUCKET_NAME)/data/training/$$timestamp/data.csv" && \
	aws s3 cp input/data/training/data.csv s3://$(AWS_MAIN_BUCKET_NAME)/data/training/latest/data.csv --region $(AWS_REGION) && \
	echo "$$timestamp" | aws s3 cp - s3://$(AWS_MAIN_BUCKET_NAME)/data/training/latest/version.txt --region $(AWS_REGION) && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Version file created: version.txt → $$timestamp" && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Copied to latest: s3://$(AWS_MAIN_BUCKET_NAME)/data/training/latest/data.csv" && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/s3/buckets/$(AWS_MAIN_BUCKET_NAME)?region=$(AWS_REGION)&prefix=data%2Ftraining%2F&showversions=false&tab=objects"

check-main-bucket:  ## Check if the main AWS S3 bucket exists
	aws s3 ls s3://$(AWS_MAIN_BUCKET_NAME) --region $(AWS_REGION)
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Bucket s3://$(AWS_MAIN_BUCKET_NAME) exists in region $(AWS_REGION)"

show-latest-dataset-version:  ## Show the latest dataset version
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Latest dataset version:"
	aws s3 cp s3://$(AWS_MAIN_BUCKET_NAME)/data/training/latest/version.txt - --region $(AWS_REGION)


# ====================================================
#  AWS ECR
# ====================================================

create-ecr-training-repository:  ## Create the AWS ECR repository for training (if not exists)
	if aws ecr describe-repositories --repository-names $(AWS_ECR_TRAINING_REPOSITORY_NAME) --region $(AWS_REGION) >/dev/null 2>&1; then \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - ECR repository already exists: $(AWS_ECR_TRAINING_REPOSITORY_NAME) in region $(AWS_REGION)"; \
	else \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating new ECR repository: $(AWS_ECR_TRAINING_REPOSITORY_NAME)..."; \
		aws ecr create-repository \
			--repository-name $(AWS_ECR_TRAINING_REPOSITORY_NAME) \
			--image-scanning-configuration scanOnPush=true \
			--encryption-configuration encryptionType=AES256 \
			--region $(AWS_REGION); \
		echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - AWS ECR repository $(AWS_ECR_TRAINING_REPOSITORY_NAME) created in region $(AWS_REGION)";
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/ecr/private-registry/repositories?region=$(AWS_REGION)"; \
	fi

create-ecr-inference-repository:  ## Create the AWS ECR repository for inference (if not exists)
	if aws ecr describe-repositories --repository-names $(AWS_ECR_INFERENCE_REPOSITORY_NAME) --region $(AWS_REGION) >/dev/null 2>&1; then \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - ECR repository already exists: $(AWS_ECR_INFERENCE_REPOSITORY_NAME) in region $(AWS_REGION)"; \
	else \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating new ECR repository: $(AWS_ECR_INFERENCE_REPOSITORY_NAME)..."; \
		aws ecr create-repository \
			--repository-name $(AWS_ECR_INFERENCE_REPOSITORY_NAME) \
			--image-scanning-configuration scanOnPush=true \
			--encryption-configuration encryptionType=AES256 \
			--region $(AWS_REGION); \
		echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - AWS ECR repository $(AWS_ECR_INFERENCE_REPOSITORY_NAME) created in region $(AWS_REGION)"; \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/ecr/private-registry/repositories?region=$(AWS_REGION)"; \
	fi

tag-training-image-amd64:  ## Tag the training Docker image for amd64
	docker tag $(IMAGE_NAME)-training-amd64:latest $(AWS_ECR_TRAINING_REPOSITORY_URL):latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker image for amd64 tagged as $(AWS_ECR_TRAINING_REPOSITORY_URL):latest"

tag-inference-image-amd64:  ## Tag the inference Docker image for amd64
	docker tag $(IMAGE_NAME)-inference-amd64:latest $(AWS_ECR_INFERENCE_REPOSITORY_URL):latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Inference Docker image for amd64 tagged as $(AWS_ECR_INFERENCE_REPOSITORY_URL):latest"

push-training-image-amd64:  ## Push the training Docker image to the AWS repository
	docker push $(AWS_ECR_TRAINING_REPOSITORY_URL):latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training Docker image for amd64 pushed to the AWS repository $(AWS_ECR_TRAINING_REPOSITORY_URL)"
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/ecr/repositories/private/$(AWS_ACCOUNT_ID)/$(AWS_ECR_TRAINING_REPOSITORY_NAME)?region=$(AWS_REGION)"

push-inference-image-amd64:  ## Push the inference Docker image to the AWS repository
	docker push $(AWS_ECR_INFERENCE_REPOSITORY_URL):latest
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Inference Docker image for amd64 pushed to the AWS repository $(AWS_ECR_INFERENCE_REPOSITORY_URL)"
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/ecr/repositories/private/$(AWS_ACCOUNT_ID)/$(AWS_ECR_INFERENCE_REPOSITORY_NAME)?region=$(AWS_REGION)"


# ====================================================
#  AWS SageMaker
# ====================================================

TIMESTAMP = $(shell date +%Y-%m-%d-%H-%M-%S)

sagemaker-deploy-training:  ## Deploy the training job using the latest dataset version
	dataset_ts=$$(aws s3 cp s3://$(AWS_MAIN_BUCKET_NAME)/data/training/latest/version.txt - --region $(AWS_REGION)) && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Launching training job using dataset version: $$dataset_ts" && \
	aws sagemaker create-training-job \
		--region $(AWS_REGION) \
		--training-job-name $(PROJECT_NAME)-training-job-$(TIMESTAMP) \
		--role-arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/SageMakerExecutionRole \
		--algorithm-specification TrainingImage=$(AWS_ECR_TRAINING_REPOSITORY_URL):latest,TrainingInputMode=File \
		--resource-config InstanceType=ml.m5.large,InstanceCount=1,VolumeSizeInGB=4 \
		--stopping-condition MaxRuntimeInSeconds=3600 \
		--output-data-config S3OutputPath=s3://$(AWS_MAIN_BUCKET_NAME)/models/$(TIMESTAMP)/ \
		--input-data-config "[{\"ChannelName\":\"training\",\"DataSource\":{\"S3DataSource\":{\"S3DataType\":\"S3Prefix\",\"S3Uri\":\"s3://$(AWS_MAIN_BUCKET_NAME)/data/training/$$dataset_ts/\",\"S3DataDistributionType\":\"FullyReplicated\"}},\"ContentType\":\"text/csv\",\"InputMode\":\"File\"}]" && \
	aws s3 cp s3://$(AWS_MAIN_BUCKET_NAME)/data/training/$$dataset_ts/data.csv \
	s3://$(AWS_MAIN_BUCKET_NAME)/models/$(TIMESTAMP)/$(PROJECT_NAME)-training-job-$(TIMESTAMP)/input/data.csv --region $(AWS_REGION) && \
	echo "$$dataset_ts" | aws s3 cp - \
	s3://$(AWS_MAIN_BUCKET_NAME)/models/$(TIMESTAMP)/$(PROJECT_NAME)-training-job-$(TIMESTAMP)/input/version.txt --region $(AWS_REGION) && \
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Training job launched using dataset version: $$dataset_ts" && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Dataset copied to model input folder" && \
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/sagemaker/home?region=$(AWS_REGION)#/jobs/$(PROJECT_NAME)-training-job-$(TIMESTAMP)"

sagemaker-register-model:  ## Create a SageMaker model from training output (TIMESTAMP must be provided)
	if [ -z "$(TIMESTAMP)" ]; then \
	  echo "$(RED)[ERROR]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - TIMESTAMP not provided"; \
	  echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Usage: make sagemaker-create-model TIMESTAMP=2025-11-11-12-12-51"; \
	  exit 1; \
	fi
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating model with TIMESTAMP=$(TIMESTAMP)"
	aws sagemaker create-model \
	  --region $(AWS_REGION) \
	  --model-name $(PROJECT_NAME)-model-api \
	  --primary-container Image=$(AWS_ECR_INFERENCE_REPOSITORY_URL):latest,ModelDataUrl="s3://$(AWS_MAIN_BUCKET_NAME)/models/$(TIMESTAMP)/$(PROJECT_NAME)-training-job-$(TIMESTAMP)/output/model.tar.gz" \
	  --execution-role-arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/SageMakerExecutionRole
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Model created: $(PROJECT_NAME)-model-api"
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/sagemaker/home?region=$(AWS_REGION)#/models"


# ====================================================
#  Real-time Endpoints (Inference)
# ====================================================

sagemaker-create-endpoint-config:  ## Create the SageMaker endpoint config
	if aws sagemaker describe-endpoint-config \
		--endpoint-config-name $(PROJECT_NAME)-endpoint-config \
		--region $(AWS_REGION) >/dev/null 2>&1; then \
			echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Endpoint config already exists: $(PROJECT_NAME)-endpoint-config"; \
	else \
		echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating endpoint config: $(PROJECT_NAME)-endpoint-config..."; \
		aws sagemaker create-endpoint-config \
		  --region $(AWS_REGION) \
		  --endpoint-config-name $(PROJECT_NAME)-endpoint-config \
		  --production-variants VariantName=AllTraffic,ModelName=$(PROJECT_NAME)-model-api,InitialInstanceCount=1,InstanceType=ml.m5.large \
		  --tags Key=Project,Value=$(PROJECT_NAME); \
		echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Endpoint config created: $(PROJECT_NAME)-endpoint-config"; \
	fi
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/sagemaker/home?region=$(AWS_REGION)#/endpointConfig"

sagemaker-create-endpoint:  ## Deploy the real-time endpoint
	if aws sagemaker describe-endpoint \
		--endpoint-name $(PROJECT_NAME)-endpoint \
		--region $(AWS_REGION) >/dev/null 2>&1; then \
			echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Endpoint already exists: $(PROJECT_NAME)-endpoint"; \
	else \
			echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Creating endpoint: $(PROJECT_NAME)-endpoint..."; \
			aws sagemaker create-endpoint \
			  --region $(AWS_REGION) \
			  --endpoint-name $(PROJECT_NAME)-endpoint \
			  --endpoint-config-name $(PROJECT_NAME)-endpoint-config; \
			echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Endpoint creation initiated: $(PROJECT_NAME)-endpoint"; \
	fi
	echo "🔗 https://$(AWS_REGION).console.aws.amazon.com/sagemaker/home?region=$(AWS_REGION)#/endpoints"


# ====================================================
#  Batch Transform (Inference)
# ====================================================

sagemaker-run-batch-transform:  ## Run the SageMaker batch transform job
	aws sagemaker create-transform-job \
	  --region $(AWS_REGION) \
	  --transform-job-name $(PROJECT_NAME)-inference-job-$(shell date +%Y-%m-%d-%H-%M-%S) \
	  --model-name $(PROJECT_NAME)-model-api \
	  --batch-strategy MultiRecord \
	  --transform-input "DataSource={S3DataSource={S3DataType=S3Prefix,S3Uri=s3://$(AWS_MAIN_BUCKET_NAME)/inference/inputs/}}" \
	  --transform-output S3OutputPath="s3://$(AWS_MAIN_BUCKET_NAME)/inference/predictions/" \
	  --transform-resources InstanceType=ml.m5.large,InstanceCount=1
	echo "$(GREEN)[SUCCESS]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - Batch transform job launched successfully"
	echo "$(BLUE)[INFO]$(NC) $$(date '+%Y-%m-%d %H:%M:%S') - 🔗 https://$(AWS_REGION).console.aws.amazon.com/sagemaker/home?region=$(AWS_REGION)#/transform-jobs"


# ====================================================
#  Pipelines
# ====================================================

pipeline-local-training: build-training-arm64 run-training-arm64  ## Run the local training pipeline

pipeline-sagemaker-training: build-training-amd64 authenticate-aws create-bucket upload-data-to-bucket create-ecr-training-repository tag-training-image-amd64 push-training-image-amd64 sagemaker-deploy-training  ## Run the SageMaker training pipeline

pipeline-local-inference: build-inference-arm64 run-inference-arm64  ## Run the local inference pipeline

pipeline-sagemaker-inference: build-inference-amd64 authenticate-aws create-ecr-inference-repository tag-inference-image-amd64 push-inference-image-amd64  ## Run the SageMaker inference pipeline
