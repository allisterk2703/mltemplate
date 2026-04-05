# src/mltemplate/utils/formatting.py

from src.mltemplate.core.logger import get_logger


logger = get_logger()


def header(text: str, width: int = 50, char: str = "=") -> str:
    """Format a centered section header with padding characters on both sides."""
    text = f" {text.strip()} "
    remaining = max(width - len(text), 0)
    left = remaining // 2
    right = remaining - left
    return f"{char * left}{text}{char * right}"


if __name__ == "__main__":
    logger.info(header("TEST"))
