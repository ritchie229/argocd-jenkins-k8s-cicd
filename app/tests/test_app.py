import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import app

def test_index():
    client = app.test_client()
    res = client.get("/")
    assert res.status_code == 200
    assert b"Hello from" in res.data

