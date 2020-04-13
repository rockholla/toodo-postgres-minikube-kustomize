from locust import HttpLocust, TaskSet, task, between

class ToodoTests(TaskSet):
    @task
    def index(self):
        self.client.get("/")

class HttpTests(HttpLocust):
    task_set = ToodoTests
    wait_time = between(1, 3)
