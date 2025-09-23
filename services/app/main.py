from fastapi import FastAPI
import time, json


app = FastAPI()


def fib(n: int) -> int:
    if n < 2: 
        return n
    a,b = 0,1
    for _ in range(n-1): 
        a,b = b,a+b
    return b


@app.get("/compute")
def compute(n: int = 35):
    t0 = time.perf_counter()
    res = fib(n)
    dt_ms = (time.perf_counter() - t0) * 1000
    return {"endpoint": "compute", "n": n, "result": res, "latency_ms": round(dt_ms,2)}


@app.get("/io")
def io():
    t0 = time.perf_counter()
    payload = {"ts": time.time(), "msg": "hello"}
    s = json.dumps(payload)   # simulate write
    _ = json.loads(s)         # simulate read
    dt_ms = (time.perf_counter() - t0) * 1000
    return {"endpoint": "io", "latency_ms": round(dt_ms, 2)}


@app.get("/")
def root():
    return {"ok": True}