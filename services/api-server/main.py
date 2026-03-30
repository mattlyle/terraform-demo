import json
import os
from contextlib import asynccontextmanager
from typing import Optional

import boto3
import psycopg2
import psycopg2.pool
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ── Config from environment variables ─────────────────────────────────────────
DB_HOST     = os.environ["DB_HOST"]
DB_PORT     = os.environ.get("DB_PORT", "5432")
DB_NAME     = os.environ["DB_NAME"]
DB_USER     = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]
AWS_REGION    = os.environ.get("AWS_REGION", "us-east-1")

sqs = boto3.client("sqs", region_name=AWS_REGION)

_pool: Optional[psycopg2.pool.SimpleConnectionPool] = None


def get_pool() -> psycopg2.pool.SimpleConnectionPool:
    global _pool
    if _pool is None:
        _pool = psycopg2.pool.SimpleConnectionPool(
            1, 10,
            host=DB_HOST, port=DB_PORT,
            dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
        )
    return _pool


def create_tables() -> None:
    pool = get_pool()
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS jobs (
                    id            BIGSERIAL PRIMARY KEY,
                    job_length_ms INTEGER NOT NULL,
                    status        VARCHAR(20) NOT NULL DEFAULT 'queued',
                    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    started_at    TIMESTAMPTZ,
                    completed_at  TIMESTAMPTZ
                )
            """)
        conn.commit()
    finally:
        pool.putconn(conn)


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_tables()
    yield


app = FastAPI(title="Demo API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Models ─────────────────────────────────────────────────────────────────────

class CreateJobRequest(BaseModel):
    job_length_ms: int = Field(default=5000, ge=100, le=30000,
                               description="How long the worker should sleep (ms)")


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.post("/api/jobs", status_code=201)
def create_job(body: CreateJobRequest):
    pool = get_pool()
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO jobs (job_length_ms, status) VALUES (%s, 'queued') RETURNING id",
                (body.job_length_ms,),
            )
            job_id = cur.fetchone()[0]
        conn.commit()
    except Exception as exc:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(exc))
    finally:
        pool.putconn(conn)

    sqs.send_message(
        QueueUrl=SQS_QUEUE_URL,
        MessageBody=json.dumps({"job_id": job_id, "job_length_ms": body.job_length_ms}),
    )

    return {"job_id": job_id, "job_length_ms": body.job_length_ms, "status": "queued"}


@app.get("/api/stats")
def get_stats():
    pool = get_pool()
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    MIN(job_length_ms),
                    MAX(job_length_ms),
                    ROUND(AVG(job_length_ms))
                FROM jobs
                WHERE status = 'completed'
            """)
            row = cur.fetchone()
    finally:
        pool.putconn(conn)

    if row[0] is None:
        return {"shortest_ms": None, "longest_ms": None, "avg_ms": None}

    return {
        "shortest_ms": row[0],
        "longest_ms":  row[1],
        "avg_ms":      int(row[2]),
    }


@app.get("/api/jobs")
def list_jobs():
    pool = get_pool()
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, job_length_ms, status, created_at, started_at, completed_at
                FROM jobs
                ORDER BY created_at DESC
                LIMIT 1000
            """)
            rows = cur.fetchall()
    finally:
        pool.putconn(conn)

    return [
        {
            "id":            row[0],
            "job_length_ms": row[1],
            "status":        row[2],
            "created_at":    row[3].isoformat() if row[3] else None,
            "started_at":    row[4].isoformat() if row[4] else None,
            "completed_at":  row[5].isoformat() if row[5] else None,
        }
        for row in rows
    ]
