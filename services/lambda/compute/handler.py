import json, time


def fib(n: int) -> int:
    if n < 2: return n
    a,b = 0,1
    for _ in range(n-1): a,b = b,a+b
    return b


def handler(event, context):
    n = int(event.get("queryStringParameters", {}).get("n", 35))
    t0 = time.perf_counter()
    res = fib(n)
    dt_ms = (time.perf_counter() - t0) * 1000
    return {"statusCode": 200, "body": json.dumps({"endpoint":"compute","n":n,"result":res,"latency_ms":round(dt_ms,2)})}