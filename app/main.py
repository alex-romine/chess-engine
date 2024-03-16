from fastapi import FastAPI, Request
from fastapi.responses import Response
from mangum import Mangum
from pydantic import BaseModel
from starlette.middleware.cors import CORSMiddleware
from stockfish import Stockfish
import json
import os
import tarfile
import urllib.request
import uvicorn


stockfish_tag = os.getenv("SF_VERSION", default="sf_16.1")
stockfish_arch = os.getenv("SF_ARCH", default="macos-m1-apple-silicon")
engine_dir = "./app/engine"

app = FastAPI()
handler = Mangum(app)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.options("/{any_path:path}")
async def preflight_handler(*, _any_path: str, _request: Request):
    return Response(status_code=204)


@app.middleware("http")
async def add_custom_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response


@app.get("/healthz")
def healthcheck():
    return {"status": "ok"}


class EngineRequest(BaseModel):
    fen: str
    depth: int | None = 16


def download_stockfish():
    
    if os.path.exists(f"{engine_dir}/stockfish/"):
        print("Stockfish dir already exists")
        return

    # Download stockfish
    print(f"Downloading stockfish")
    url = f"https://github.com/official-stockfish/Stockfish/releases/download/{stockfish_tag}/stockfish-{stockfish_arch}.tar"
    file_path = f"{engine_dir}/stockfish.tar"
    urllib.request.urlretrieve(url, file_path)

    # Extract the tar file
    with tarfile.open(file_path, "r") as tar:
        tar.extractall(path=engine_dir)
    

def run_eval(fen: str, depth: int):
    print(f"Running stockfish eval")
    stockfish = Stockfish(path=f"{engine_dir}/stockfish/stockfish-{stockfish_arch}", depth=depth, parameters={"Threads": 2, "Hash": 64})

    stockfish.set_fen_position(fen)
    eval = stockfish.get_top_moves(3)

    print(f"Eval: {eval}")
    return eval
        

# FastAPI endpoints for commands
@app.post("/best_moves")
def best_moves(request: EngineRequest):
    request_str = json.dumps(request.dict())
    request_json = json.loads(request_str)
    
    fen = request_json["fen"]
    print(f"fen: {fen}")
    depth = request_json["depth"]
    print(f"depth: {depth}")

    download_stockfish()
    eval = run_eval(fen, depth)

    return {"eval": eval}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)