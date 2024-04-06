from pathlib import Path
# from app.stockfish import Stockfish
from stockfish import Stockfish
import json
import os
import tarfile
import urllib.request
import uvicorn


stockfish_tag = os.getenv("SF_VERSION", default="sf_16.1")
print(f"stockfish_tag: {stockfish_tag}")
stockfish_arch = os.getenv("SF_ARCH", default="armv8")
print(f"stockfish_arch: {stockfish_arch}")

engine_dir = "./app/engine"
executable_location = f"{engine_dir}/stockfish/stockfish-{stockfish_arch}"
print(f"executable_location: {executable_location}")


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
    stockfish = Stockfish(path=executable_location, depth=depth)
                            
    stockfish.set_fen_position(fen)
    top_moves = stockfish.get_top_moves(3)

    print(f"Top moves: {top_moves}")
    return top_moves
        

def handler(event, context):
    print(f"Event: {event}")
    body = json.loads(event['body'])
    fen = body['fen']
    depth = body.get('depth', 12)

    download_stockfish()
    eval = run_eval(fen, depth)

    return {
        'statusCode': 200,
        'body': json.dumps({"eval": f"{eval}"})
    }
