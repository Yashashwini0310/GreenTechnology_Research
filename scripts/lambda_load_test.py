import os
import time
import argparse
import requests

def run_test(name: str, base_url: str, duration_s: int, delay_s: float, is_compute: bool):
    """
    name: label to print (e.g. 'compute_low')
    base_url: full Lambda function URL (ending with /)
    duration_s: how long to run
    delay_s: sleep between requests (controls rate)
    is_compute: if True, call ?n=35; else just /
    """
    print(f"Starting Lambda test: {name}")
    print(f"URL: {base_url}")
    print(f"Duration: {duration_s}s, delay: {delay_s}s")
    end_time = time.time() + duration_s

    count = 0
    failures = 0
    latencies = []
    start_ts = time.time()

    while time.time() < end_time:
        try:
            if is_compute:
                url = f"{base_url}?n=35"
            else:
                url = base_url

            t0 = time.perf_counter()
            resp = requests.get(url, timeout=10)
            dt = (time.perf_counter() - t0) * 1000  # ms

            if resp.status_code == 200:
                count += 1
                latencies.append(dt)
            else:
                failures += 1
                print(f"Non-200 status: {resp.status_code}, body={resp.text[:100]}")
        except Exception as e:
            failures += 1
            print(f"Request error: {e}")

        time.sleep(delay_s)

    end_ts = time.time()

    print(f"=== {name} summary ===")
    print(f"Start time (approx, UTC): {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(start_ts))}")
    print(f"End time   (approx, UTC): {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(end_ts))}")
    print(f"Successful requests: {count}")
    print(f"Failed requests:     {failures}")

    if latencies:
        latencies.sort()
        n = len(latencies)
        p50 = latencies[int(0.5*n)]
        p90 = latencies[int(0.9*n)]
        p99 = latencies[int(0.99*n)-1]
        avg = sum(latencies) / n
        print(f"Avg latency: {avg:.2f} ms, p50={p50:.2f}, p90={p90:.2f}, p99={p99:.2f}")
    else:
        print("No successful responses to compute latency stats.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True, help="Lambda Function URL (e.g. https://xxx.lambda-url.us-east-1.on.aws/)")
    parser.add_argument("--name", required=True, help="Label for this run (e.g. compute_low)")
    parser.add_argument("--duration", type=int, default=120, help="Duration in seconds")
    parser.add_argument("--delay", type=float, default=0.1, help="Delay between requests in seconds")
    parser.add_argument("--compute", action="store_true", help="If set, call ?n=35 (compute endpoint). Otherwise IO/root.")
    args = parser.parse_args()

    run_test(args.name, args.url.rstrip("/"), args.duration, args.delay, args.compute)
