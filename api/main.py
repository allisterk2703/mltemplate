# api/main.py

import json
import sys
from pathlib import Path

from fastapi import FastAPI

from src.mltemplate.core.logger import get_logger


logger = get_logger()

sys.path.insert(0, str(Path(__file__).parent.parent))

PROJECT_NAME = (Path(__file__).resolve().parents[1]).name

app = FastAPI(
    title=f"Prediction API - {PROJECT_NAME}",
    description=f"Serve machine learning predictions for {PROJECT_NAME}",
    version="1.0.0",
)

schema_path = Path(__file__).parent.parent / "input" / "df_schema.json"
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
