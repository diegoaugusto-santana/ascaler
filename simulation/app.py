"""Simulation app: each request burns 50 ms of CPU and returns the hostname."""
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
import socket
import time


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        end = time.thread_time() + 0.05
        while time.thread_time() < end:
            pass
        body = ("Hostname: %s\n" % socket.gethostname()).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("", 80), Handler).serve_forever()
