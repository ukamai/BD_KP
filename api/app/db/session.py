from typing import Generator, Optional

from fastapi import Header
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

from app.core.config import DATABASE_URL

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_reset_on_return="rollback",  
)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def get_db(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")) -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        db.rollback()

        if x_user_id is not None:
            db.execute(text("SELECT set_config('app.user_id', :uid, true)"), {"uid": str(x_user_id)})

        yield db

    except Exception:
        db.rollback()
        raise
    finally:
        try:
            db.rollback()
        finally:
            db.close()
