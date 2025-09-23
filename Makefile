setup run-app run-load deploy-aws deploy-gcp destroy-aws destroy-gcp fmt lint test


setup:
python -m pip install -r services/app/requirements.txt
python -m pip install locust boto3 google-cloud-monitoring google-cloud-billing pandas numpy scipy matplotlib


run-app:
uvicorn services.app.main:app --port 8000


run-load:
locust -f load_tests/locustfile.py --headless -u 100 --spawn-rate 10 -H http://127.0.0.1:8000 -t 5m


deploy-aws:
cd infra/aws/terraform && terraform init && terraform apply -auto-approve


deploy-gcp:
cd infra/gcp/terraform && terraform init && terraform apply -auto-approve


destroy-aws:
cd infra/aws/terraform && terraform destroy -auto-approve


destroy-gcp:
cd infra/gcp/terraform && terraform destroy -auto-approve


fmt:
python -m black services scripts analysis


lint:
python -m flake8 services scripts analysis


test:
pytest -q