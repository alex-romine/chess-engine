# For building in python docker container
apt update
apt install -y g++ curl make

curl -L -O https://github.com/official-stockfish/Stockfish/archive/refs/tags/sf_16.1.tar.gz
tar -xv sf_16.1.tar.gz

cd stockfish/src
make -j profile-build ARCH=armv8