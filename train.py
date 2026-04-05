#!/usr/bin/env python3


from src.mltemplate.config.config import load_config, parse_config, print_config
from src.mltemplate.config.mlflow import print_mlflow_config
from src.mltemplate.config.paths import CONFIG_PATH, print_paths


def main() -> None:
    """Execute the complete ML pipeline from data loading to model evaluation."""
    config = parse_config(load_config(CONFIG_PATH))
    print_config(config)
    print_paths()
    print_mlflow_config()

    # 1) Loading

    # 2) Splitting

    # 3) Preprocessing

    # 4) Encoding

    # 5) Scaling

    # 6) Training

    # 7) Generate example input


if __name__ == "__main__":
    main()
