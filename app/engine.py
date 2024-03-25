import subprocess
    
class Stockfish:
    """Integrates the Stockfish chess engine with Python."""
    
    def __init__(self, path: str, depth: int, threads: int, hash: int, multipv: int = 3):
        self._path = path
        self._depth = str(depth)
        self._threads = str(threads)
        self._hash = str(hash)
        self._multipv = multipv

        self._stockfish = subprocess.Popen(
            self._path,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            shell=True,
        )
        
        self.send_command("uci")
        self._send_isready()

        self.send_command(f"setoption name Threads value {self._threads}")
        self.send_command(f"setoption name Hash value {self._hash}")
        self.send_command(f"setoption name MultiPV value {self._multipv}")
    

    def _send_isready(self):
        self.send_command("isready")
        while self._read_line() != "readyok":
            pass
    
    def send_command(self, command: str):
        self._stockfish.stdin.write(command + "\n")
        self._stockfish.stdin.flush()
        
    def get_top_moves(self) -> list:
        self.send_command(f"go depth {self._depth}")
        num_top_moves = self._multipv
        lines = []
        
        while True:
            text = self._read_line()
            splitted_text = text.split(" ")
            lines.append(splitted_text)
            if splitted_text[0] == "bestmove":
                break  
        
        top_moves = []
        
        for current_line in reversed(lines):
            if current_line[0] == "bestmove":
                if current_line[1] == "(none)":
                    top_moves = []
                    break
            elif (
                ("multipv" in current_line)
                and ("depth" in current_line)
                and current_line[current_line.index("depth") + 1] == self._depth
            ):
                multiPV_number = int(current_line[current_line.index("multipv") + 1])
                if multiPV_number <= num_top_moves:
                    has_centipawn_value = "cp" in current_line
                    has_mate_value = "mate" in current_line
                    if has_centipawn_value == has_mate_value:
                        raise RuntimeError(
                            "Having a centipawn value and mate value should be mutually exclusive."
                        )
                    top_moves.insert(
                        0,
                        {
                            "Move": current_line[current_line.index("pv") + 1],
                            "Centipawn": int(current_line[current_line.index("cp") + 1])
                            if has_centipawn_value
                            else None,
                            "Mate": int(current_line[current_line.index("mate") + 1])
                            if has_mate_value
                            else None,
                        },
                    )
            else:
                break
                
        print(f"Top moves: {top_moves}")
        return top_moves

    def _read_line(self) -> str:
        if not self._stockfish.stdout:
            raise BrokenPipeError()
        if self._stockfish.poll() is not None:
            raise StockfishException("Stockfish died.")
        return self._stockfish.stdout.readline().strip()
        
class StockfishException(Exception):
    pass