# src/mltemplate/config/mlflow.py

import os
from urllib.parse import urlparse

import requests
from dotenv import load_dotenv
from minio import Minio

from src.mltemplate.config.paths import BASE_DIR, PROJECT_NAME
from src.mltemplate.core.logger import get_logger
from src.mltemplate.utils.formatting import header


logger = get_logger()
load_dotenv(override=True)


MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI")
MLFLOW_S3_ENDPOINT_URL = os.getenv("MLFLOW_S3_ENDPOINT_URL")
MINIO_ROOT_USER = os.getenv("MINIO_ROOT_USER")
MINIO_ROOT_PASSWORD = os.getenv("MINIO_ROOT_PASSWORD")
MLFLOW_HOST = os.getenv("MLFLOW_HOST")
MLFLOW_PORT = os.getenv("MLFLOW_PORT")
if MLFLOW_S3_ENDPOINT_URL is not None:
    os.environ["MLFLOW_S3_ENDPOINT_URL"] = MLFLOW_S3_ENDPOINT_URL
if MINIO_ROOT_USER is not None:
    os.environ["AWS_ACCESS_KEY_ID"] = MINIO_ROOT_USER
if MINIO_ROOT_PASSWORD is not None:
    os.environ["AWS_SECRET_ACCESS_KEY"] = MINIO_ROOT_PASSWORD


def check_mlflow_availability(timeout_s: int = 2) -> bool:
    """Check if MLflow server is available."""
    MLFLOW_TRACKING_URI = f"http://{MLFLOW_HOST}:{MLFLOW_PORT}"
    try:
        r = requests.get(
            f"{MLFLOW_TRACKING_URI}/version",
            timeout=timeout_s,
        )
        return r.status_code == 200
    except requests.RequestException:
        return False


MLFLOW_AVAILABLE = check_mlflow_availability()


def print_mlflow_config() -> None:
    """Print MLflow configuration details."""
    logger.info(header("MLFLOW CONFIG"))
    logger.info(f"BASE_DIR               = {BASE_DIR}")
    logger.info(f"PROJECT_NAME           = {PROJECT_NAME}")
    logger.info(f"MLFLOW_HOST            = {MLFLOW_HOST}")
    logger.info(f"MLFLOW_PORT            = {MLFLOW_PORT}")
    logger.info(f"MLFLOW_AVAILABLE       = {MLFLOW_AVAILABLE}")
    logger.info(f"MLFLOW_S3_ENDPOINT_URL = {os.environ.get('MLFLOW_S3_ENDPOINT_URL')}")
    logger.info(50 * "=" + "\n")


def create_minio_bucket(bucket_name: str) -> None:
    """Create a MinIO bucket if it doesn't exist."""

    if MLFLOW_S3_ENDPOINT_URL is None or MINIO_ROOT_USER is None or MINIO_ROOT_PASSWORD is None:
        raise ValueError("Missing required MinIO configuration in environment variables")

    # Parse endpoint URL to remove http:// or https://
    parsed_url = urlparse(MLFLOW_S3_ENDPOINT_URL)
    endpoint = parsed_url.netloc if parsed_url.netloc else parsed_url.path
    secure = parsed_url.scheme == "https"

    client = Minio(endpoint, access_key=MINIO_ROOT_USER, secret_key=MINIO_ROOT_PASSWORD, secure=secure)

    try:
        if not client.bucket_exists(bucket_name):
            client.make_bucket(bucket_name)
            logger.info(f"Bucket {bucket_name} created successfully in MinIO")
        else:
            logger.info(f"Bucket {bucket_name} already exists in MinIO")
    except Exception as e:
        raise Exception(f"Error creating MinIO bucket: {e}") from e


if __name__ == "__main__":
    print_mlflow_config()
    create_minio_bucket("mlflow")
