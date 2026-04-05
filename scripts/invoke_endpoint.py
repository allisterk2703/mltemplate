# scripts/invoke_endpoint.py

import json
import os
from pathlib import Path

import boto3
from dotenv import load_dotenv


load_dotenv()

PROJECT_NAME = Path(__file__).resolve().parents[1].name
ENDPOINT_NAME = f"{PROJECT_NAME}-endpoint"
AWS_REGION = os.getenv("AWS_REGION")

# Load example JSON
example_path = Path(__file__).resolve().parents[1] / "input" / "example_input.json"
with example_path.open() as f:
    payload = json.load(f)

# SageMaker runtime client
client = boto3.client("sagemaker-runtime", region_name=AWS_REGION)

# Call the endpoint
response = client.invoke_endpoint(
    EndpointName=ENDPOINT_NAME,
    ContentType="application/json",
    Body=json.dumps(payload),
)

# Result
result = json.loads(response["Body"].read().decode())
print("✅ Prediction:", result)
