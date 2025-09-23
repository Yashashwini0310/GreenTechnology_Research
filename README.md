# Energy & Water Footprint of Cloud Compute Models


This repository contains code and infrastructure to compare sustainability across **VMs**, **managed containers**, and **serverless** on **AWS** and **GCP** using identical workloads.


## Quick Start
1. Create and export cloud creds (AWS CLI / gcloud). Copy `.env.example` → `.env`.
2. Install Python 3.11+ and Docker. `pip install -r services/app/requirements.txt`.
3. Run the service locally: `uvicorn services.app.main:app --reload --port 8000`.
4. Run a pilot load: `locust -f load_tests/locustfile.py --headless -u 100 --spawn-rate 10 -H http://127.0.0.1:8000 -t 5m`.
5. (AWS) `make deploy-aws` then test the public endpoints.
6. Collect metrics: `python scripts/process_locust_stats.py ...` then `python scripts/collect_metrics_aws.py ...`.


## Repo Layout
See top-level tree. Infra uses Terraform; analysis uses Python (pandas / numpy / scipy / matplotlib).