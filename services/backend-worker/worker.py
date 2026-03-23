"""
Backend worker — consumes jobs from SQS and simulates processing.

Flow:
  1. Receive a message from the SQS jobs queue (long-polling).
  2. Mark the job as 'processing' in PostgreSQL.
  3. Sleep for job_length_ms to simulate work.
  4. Mark the job as 'completed' in PostgreSQL.
  5. Delete the message from SQS.
"""

import json
import os
import signal
import sys
import time

import boto3
import psycopg2

SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]
DB_HOST       = os.environ["DB_HOST"]
DB_PORT       = os.environ.get("DB_PORT", "5432")
DB_NAME       = os.environ["DB_NAME"]
DB_USER       = os.environ["DB_USER"]
DB_PASSWORD   = os.environ["DB_PASSWORD"]
AWS_REGION    = os.environ.get("AWS_REGION", "us-east-1")

sqs = boto3.client("sqs", region_name=AWS_REGION)

running = True


def _shutdown(signum, frame):
    global running
    print("Shutdown signal received — finishing current job then exiting.", flush=True)
    running = False


signal.signal(signal.SIGTERM, _shutdown)
signal.signal(signal.SIGINT, _shutdown)


def get_conn():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT,
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
    )


def process(message: dict) -> None:
    body = json.loads(message["Body"])
    job_id        = body["job_id"]
    job_length_ms = body["job_length_ms"]
    receipt       = message["ReceiptHandle"]

    print(f"Processing job {job_id} ({job_length_ms}ms)", flush=True)

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE jobs SET status='processing', started_at=NOW() WHERE id=%s",
                (job_id,),
            )
        conn.commit()

        time.sleep(job_length_ms / 1000.0)

        with conn.cursor() as cur:
            cur.execute(
                "UPDATE jobs SET status='completed', completed_at=NOW() WHERE id=%s",
                (job_id,),
            )
        conn.commit()
    except Exception as exc:
        print(f"Error processing {job_id}: {exc}", flush=True)
        conn.rollback()
        # Leave the message in the queue so it can be retried / hit the DLQ.
        return
    finally:
        conn.close()

    sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=receipt)
    print(f"Completed job {job_id}", flush=True)


def main() -> None:
    print("Worker started", flush=True)
    while running:
        try:
            resp = sqs.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20,  # long-poll — reduces API calls when queue is empty
            )
        except Exception as exc:
            print(f"SQS receive error: {exc}", flush=True)
            time.sleep(5)
            continue

        for msg in resp.get("Messages", []):
            if not running:
                break
            try:
                process(msg)
            except Exception as exc:
                print(f"Unhandled error: {exc}", flush=True)

    print("Worker stopped", flush=True)
    sys.exit(0)


if __name__ == "__main__":
    main()
