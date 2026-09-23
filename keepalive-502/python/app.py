from fastapi import FastAPI

app = FastAPI()


@app.post("/orders")
def create_order():
    return {"ok": True}
