import json, time


def handler(event, context):
    t0 = time.perf_counter()
    payload = {"ts": time.time(), "msg": "hello"}
    # Minimal I/O-like work: serialize/deserialize
    s = json.dumps(payload)
    _ = json.loads(s)
    dt_ms = (time.perf_counter() - t0) * 1000
    return {"statusCode": 200, "body": json.dumps({"endpoint":"io","latency_ms":round(dt_ms,2)})}