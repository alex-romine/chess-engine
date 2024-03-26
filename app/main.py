from fastapi import FastAPI, Request
from fastapi.responses import Response
from mangum import Mangum
from pathlib import Path
from pydantic import BaseModel
from starlette.middleware.cors import CORSMiddleware
from app.engine import Stockfish
import json
import os
import tarfile
import urllib.request
import uvicorn


stockfish_tag = os.getenv("SF_VERSION", default="sf_16.1")
print(f"stockfish_tag: {stockfish_tag}")
stockfish_arch = os.getenv("SF_ARCH", default="macos-m1-apple-silicon")
print(f"stockfish_arch: {stockfish_arch}")

engine_dir = "./app/engine"
executable_location = f"{engine_dir}/stockfish/stockfish-{stockfish_arch}"
print(f"executable_location: {executable_location}")

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
    
    if os.path.exists(executable_location):
        print("Stockfish already exists")
        return
    
    Path(engine_dir).mkdir(parents=True, exist_ok=True)
        
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
    stockfish = Stockfish(path=executable_location, depth=depth, threads=1, hash=16)
                            
    stockfish.send_command(f"position fen {fen}")
    top_moves = stockfish.get_top_moves()

    print(f"Top moves: {top_moves}")
    return top_moves
        

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

    return {"eval": f"{eval}"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)