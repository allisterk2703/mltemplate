# src/mltemplate/utils/utils.py

import json
import os
import pathlib
import pickle
import re
from pathlib import Path
from typing import Any

import pandas as pd

from src.mltemplate.config.paths import get_input_dir, get_model_dir, get_output_dir
from src.mltemplate.core.logger import get_logger
from src.mltemplate.utils.formatting import header


logger = get_logger()


##############################################################################
# LOADING FUNCTIONS
##############################################################################


def load_pickle(name: str) -> Any:
    """Load a pickled object from the model directory."""
    model_dir = get_model_dir()
    path = model_dir / name

    if not path.exists():
        raise FileNotFoundError(f"Missing artifact: {path.resolve()}")

    with open(path, "rb") as f:
        return pickle.load(f)


def load_model(name: str = "model.pkl") -> Any:
    """Load a model from the model directory."""
    return load_pickle(name)


def load_scaler(name: str = "scaler.pkl") -> Any:
    """Load a scaler from the model directory."""
    return load_pickle(name)


def load_reducer(name: str = "dimensionality_reducer.pkl") -> Any:
    """Load a reducer from the model directory."""
    return load_pickle(name)


def load_ordinal_encoder(name: str = "ordinal_encoder.pkl") -> Any:
    """Load an ordinal encoder from the model directory."""
    return load_pickle(name)


def load_onehot_encoder(name: str = "onehot_encoder.pkl") -> Any:
    """Load a one-hot encoder from the model directory."""
    return load_pickle(name)


def load_imbalanced_binary_columns(name: str = "imbalanced_binary_columns.txt") -> list[str]:
    """Load the list of imbalanced binary columns from the model directory."""
    model_dir = get_model_dir()
    path = model_dir / name
    if not path.exists():
        raise FileNotFoundError(f"Missing artifact: {path.resolve()}")
    with open(path, encoding="utf-8") as f:
        return [line.strip() for line in f.readlines()]


def load_feature_names(name: str = "feature_names.json") -> dict[str, Any]:
    """Load feature names from saved JSON file."""
    model_dir = get_model_dir()
    path = model_dir / name
    if not path.exists():
        raise FileNotFoundError(f"Missing feature names file: {path.resolve()}")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_example_input(filename: str = "example_input.json") -> pd.DataFrame:
    """Load example input from the input directory."""
    input_dir = get_input_dir()
    path = input_dir / filename
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path.resolve()}")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    logger.info(f"Loaded example input from: {path.resolve()}")
    logger.info(f"Example input: {json.dumps(data, indent=2)}")
    return pd.DataFrame([data])


def load_artifacts() -> tuple[Any, Any, Any, Any, Any, list[str]]:
    """Load all necessary artifacts from model directory."""
    logger.info("Loading artifacts...")

    try:
        model = load_model()
        logger.info(f"Model loaded successfully from: {(get_model_dir() / 'model.pkl').resolve()}")
    except FileNotFoundError as e:
        raise FileNotFoundError(f"Could not load model: {e}") from e

    try:
        scaler = load_scaler()
        logger.info(f"Scaler loaded successfully from: {(get_model_dir() / 'scaler.pkl').resolve()}")
    except FileNotFoundError as e:
        raise FileNotFoundError(f"Could not load scaler: {e}") from e

    try:
        reducer = load_reducer()
        logger.info(f"Reducer loaded successfully from: {(get_model_dir() / 'dimensionality_reducer.pkl').resolve()}")
    except FileNotFoundError as e:
        raise FileNotFoundError(f"Could not load reducer: {e}") from e

    try:
        ordinal_encoder = load_ordinal_encoder()
        logger.info(f"Ordinal encoder loaded successfully from: {(get_model_dir() / 'ordinal_encoder.pkl').resolve()}")
    except FileNotFoundError:
        ordinal_encoder = None
        logger.info("Could not load ordinal encoder")

    try:
        onehot_encoder = load_onehot_encoder()
        logger.info(f"One-hot encoder loaded successfully from: {(get_model_dir() / 'onehot_encoder.pkl').resolve()}")
    except FileNotFoundError:
        onehot_encoder = None
        logger.info("Could not load one-hot encoder")

    try:
        imbalanced_cols = load_imbalanced_binary_columns()
        logger.info(f"Imbalanced binary columns list loaded: {len(imbalanced_cols)} columns")
    except FileNotFoundError:
        imbalanced_cols = []
        logger.info("Could not load imbalanced binary columns list (using empty list)")

    print("")

    return model, scaler, reducer, ordinal_encoder, onehot_encoder, imbalanced_cols


##############################################################################
# SAVING FUNCTIONS
##############################################################################


def save_pickle(obj, path: Path) -> None:
    """Save a pickled object to the model directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        pickle.dump(obj, f)


def save_json(obj, path: Path) -> None:
    """Save a JSON object to the model directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)


def save_dfs_to_cache(filename: str, **dfs: pd.DataFrame) -> None:
    """Save DataFrames to cache directory organized by pipeline step name."""
    # Extract script name without extension
    script_name = pathlib.Path(filename).name.split(".")[0]

    # Build folder path
    folder = pathlib.Path(f"cache/{script_name}")
    folder.mkdir(parents=True, exist_ok=True)

    # Save each dataframe
    for name, df in dfs.items():
        path = folder / f"{name}.csv"
        logger.info(f"Saving {name} to: {path}")
        df.to_csv(path, index=False)
        # print(f'Saved: {path}')
    # print("\n")


def save_predictions(predictions: pd.Series) -> None:
    """Save predictions to the output directory."""
    output_dir = get_output_dir().parent.parent
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / "prediction.json"
    with open(path, "w") as f:
        json.dump(predictions.tolist(), f)
    logger.info(f"Saved prediction to: {path}")


##############################################################################
# OTHER FUNCTIONS
##############################################################################


def clean_text(text: str) -> str:
    """Clean a single string."""
    # 1. All lowercase
    text = text.lower()
    # 2. Replace spaces and hyphens by '_'
    text = re.sub(r"[ \-]+", "_", text)
    # 3. Remove forbidden characters: [ ] < >
    text = re.sub(r"[\[\]<>]", "", text)
    return text


def normalize_columns(column_names: list[str]) -> list[str]:
    """Clean the column names."""
    return [clean_text(c) for c in column_names]


def print_environment_variables() -> None:
    """Display SageMaker environment variables if present in the current environment."""
    sm_vars = {k: v for k, v in os.environ.items() if k.startswith("SM_")}

    if not sm_vars:
        print("No SageMaker environment variables found\n")
        return

    print(header("SAGEMAKER ENVIRONMENT VARIABLES"))
    for k, v in sm_vars.items():
        print(f"{k} = {v}")
    print(50 * "=" + "\n")
