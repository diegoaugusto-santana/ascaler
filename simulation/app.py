"""App de simulacao: cada requisicao consome 50 ms de CPU e devolve o hostname."""
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
import socket
import time


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        fim = time.thread_time() + 0.05
        while time.thread_time() < fim:
            pass
        corpo = ("Hostname: %s\n" % socket.gethostname()).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(corpo)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(corpo)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("", 80), Handler).serve_forever()
