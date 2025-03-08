import time
import random

from pydantic import BaseModel


class MachineCpuUsage(BaseModel):
    id: str
    usage: int


while True:
    fake_usage = random.choice(range(100))
    m = MachineCpuUsage(id="t0", usage=fake_usage)
    print(f"machine={m.model_dump()}", flush=True)
    time.sleep(15)
