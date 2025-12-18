import os


APP_HOST = os.getenv("APP_HOST", "0.0.0.0")
APP_PORT = int(os.getenv("APP_PORT", "8000"))


def _build_database_url_from_parts() -> str:
    db_user = os.getenv("POSTGRES_USER")
    db_pass = os.getenv("POSTGRES_PASSWORD")
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("POSTGRES_DB")

    missing = []
    if not db_user:
        missing.append("POSTGRES_USER")
    if not db_pass:
        missing.append("POSTGRES_PASSWORD")
    if not db_name:
        missing.append("POSTGRES_DB")

    if missing:
        raise RuntimeError(
            "DATABASE_URL is not set and required env vars are missing: "
            + ", ".join(missing)
            + ". Set DATABASE_URL or provide POSTGRES_USER/POSTGRES_PASSWORD/POSTGRES_DB."
        )

    return f"postgresql+psycopg2://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"


DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = _build_database_url_from_parts()