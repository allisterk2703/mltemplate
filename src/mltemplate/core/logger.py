# src/mltemplate/core/logger.py

import logging
import sys
from datetime import datetime
from pathlib import Path


def get_logger() -> logging.Logger:
    """Get or create a configured logger with file and console handlers."""
    logger = logging.getLogger("titanic")
    logger.setLevel(logging.INFO)

    logger.propagate = False

    # Prevent adding multiple handlers if already configured
    if logger.handlers:
        return logger

    # logs/ directory
    BASE_DIR = Path(__file__).resolve().parents[3]
    log_dir = BASE_DIR / "cache" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    log_file = log_dir / f"logs_{timestamp}.log"

    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

    # File handler
    fh = logging.FileHandler(log_file)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    # Stdout handler
    sh = logging.StreamHandler(sys.stdout)
    sh.setFormatter(formatter)
    logger.addHandler(sh)

    logger.info(f"Log file created: {log_file}\n")
    return logger
