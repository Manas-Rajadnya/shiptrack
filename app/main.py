import os
import json
import time
import uuid
from fastapi import Request

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

@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())[:8]
    start = time.time()

    response = await call_next(request)

    duration_ms = round((time.time() - start) * 1000, 2)

    print(json.dumps({
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "level": "info",
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
        "status": response.status_code,
        "duration_ms": duration_ms,
    }), flush=True)

    response.headers["X-Request-ID"] = request_id
    return response


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
