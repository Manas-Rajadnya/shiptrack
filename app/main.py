import os

from fastapi import FastAPI, Response
from sqlalchemy import create_engine, text

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+pymysql://root:devroot@127.0.0.1:3307/shiptrack",
)

# pool_pre_ping issues a cheap SELECT 1 before handing out a pooled connection,
# so a connection killed by the DB (restart, timeout) is discarded rather than
# handed to a request that then fails. Day 26 / INC-005 breaks this on purpose.
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    pool_recycle=1800,
    connect_args={"connect_timeout": 3},
)

app = FastAPI(title="ShipTrack", version="0.1.0")


@app.get("/healthz")
def healthz():
    """Liveness: is this process alive?

    Deliberately checks NOTHING external. If this fails, the process is broken
    and restarting is the correct response. Checking the database here would
    mean a DB blip restarts every pod in the fleet — the classic mistake.
    """
    return {"status": "ok"}


@app.get("/readyz")
def readyz(response: Response):
    """Readiness: can this process serve traffic right now?

    Checks the database, because a request that needs the DB will fail without
    it. Returning 503 removes this pod from the Service endpoints — traffic
    stops arriving, but the pod is NOT restarted. It rejoins when the DB is back.
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ready", "database": "up"}
    except Exception as exc:
        response.status_code = 503
        return {"status": "not_ready", "database": "down", "error": str(exc)[:120]}
