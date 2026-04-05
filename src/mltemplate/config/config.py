# src/mltemplate/config/config.py

from pathlib import Path
from typing import Any

import yaml

from src.mltemplate.config.paths import CONFIG_PATH
from src.mltemplate.core.logger import get_logger
from src.mltemplate.utils.formatting import header


logger = get_logger()


def load_config(path: Path = CONFIG_PATH) -> dict[str, Any]:
    """Load project configuration from a YAML file."""
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    with path.open() as f:
        return yaml.safe_load(f)


def parse_config(config: dict[str, Any]) -> dict[str, Any]:
    """Cast and apply defaults to raw config values."""
    return {
        "TARGET_COLUMN": str(config["TARGET_COLUMN"]),
        "PROBLEM_TYPE": config["PROBLEM_TYPE"],
        "TARGET_MAPPING": dict(config.get("TARGET_MAPPING") or {}),
        "COLUMNS_TO_DROP": list(config.get("COLUMNS_TO_DROP") or []),
        "RANDOM_STATE": int(config.get("RANDOM_STATE", 42)),
        "TEST_SIZE": float(config.get("TEST_SIZE", 0.2)),
        "STRATIFY": bool(config.get("STRATIFY", True)),
    }


def print_config(config: dict[str, Any]) -> None:
    """Log current configuration parameters."""
    logger.info(header("CONFIG"))
    for key, value in config.items():
        logger.info(f"{key:<16} = {value}")
    logger.info(50 * "=" + "\n")


if __name__ == "__main__":
    config = parse_config(load_config())
    print_config(config)
