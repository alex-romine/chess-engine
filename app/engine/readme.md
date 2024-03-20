# How to build the binary

# 1a. ssh onto the machine, 
# 1b. install g++ and make
# 2. curl -L -O https://github.com/official-stockfish/Stockfish/archive/refs/tags/<tag>.zip
# 3. unzip <tag>.zip
# 4. cd Stockfish-<tag>/src; make -j profile-build ARCH=x86-64
# 5. scp it onto local machine (scp -i <key> ec2-user@<ip>:<abs_file_path_of_binary> <local_file_path>
