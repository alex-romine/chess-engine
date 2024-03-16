import urllib.request
import tarfile

# Download stockfish
url = "https://github.com/official-stockfish/Stockfish/releases/download/sf_16.1/stockfish-macos-m1-apple-silicon.tar"
file_path = "./engine/stockfish.tar"
urllib.request.urlretrieve(url, file_path)


# Extract the tar file
with tarfile.open(file_path, "r") as tar:
    tar.extractall("./engine")

# Run it

# Commands to interact

# FastAPI endpoints for commands