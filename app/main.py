from stockfish import Stockfish
import os
import tarfile
import urllib.request

stockfish_tag = "sf_16.1"
stockfish_arch = "macos-m1-apple-silicon"

def download_stockfish():
    
    if os.path.exists("./engine/stockfish/"):
        return

    # Download stockfish
    url = f"https://github.com/official-stockfish/Stockfish/releases/download/{stockfish_tag}/stockfish-{stockfish_arch}.tar"
    file_path = "./engine/stockfish.tar"
    urllib.request.urlretrieve(url, file_path)

    # Extract the tar file
    with tarfile.open(file_path, "r") as tar:
        tar.extractall(filter="tar", path="./engine")
    

def run_eval(fen: str):
    stockfish = Stockfish(path=f"./engine/stockfish/stockfish-{stockfish_arch}", depth=16, parameters={"Threads": 2, "Hash": 64})

    print(stockfish.get_top_moves(3))
        

# FastAPI endpoints for commands

def main():
    example_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    download_stockfish()
    run_eval(example_fen)


if __name__ == "__main__":
    main()