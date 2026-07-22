from pathlib import Path

ROOT = Path(__file__).parents[2]


def test_required_environment_roots_exist() -> None:
    for environment in ("dev", "staging", "prod"):
        root = ROOT / "environments" / environment
        for filename in ("main.tf", "variables.tf", "outputs.tf", "versions.tf", "README.md"):
            assert (root / filename).is_file()


def test_all_modules_have_required_files() -> None:
    required = {"main.tf", "variables.tf", "outputs.tf", "versions.tf", "README.md"}
    for module in (ROOT / "modules").iterdir():
        if module.is_dir():
            assert required.issubset({path.name for path in module.iterdir()}), module.name

