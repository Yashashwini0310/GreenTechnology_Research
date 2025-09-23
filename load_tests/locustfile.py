from locust import HttpUser, task, between
import random


class MicroUser(HttpUser):
    wait_time = between(0, 0)


    @task(7)
    def compute(self):
        n = random.choice([32, 35, 38])
        self.client.get(f"/compute?n={n}", name="/compute")


    @task(3)
    def io(self):
        self.client.get("/io", name="/io")