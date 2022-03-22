__author__ = "Paul Bargewell"
__copyright__ = "Copyright 2021, Opus Vision Limited T/A OpusVL"
__license__ = "AGPL-3.0-or-later"
__maintainer__ = "Paul Bargewell"
__email__ = "paul.bargewell@opusvl.com"

from threading import Thread
from socketserver import ThreadingMixIn
from http.server import HTTPServer, BaseHTTPRequestHandler, SimpleHTTPRequestHandler

PORTS = [8069, 8070]
 
class MyHttpRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        self.path = 'maintenance/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)
 
Handler = MyHttpRequestHandler

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

def serve_on_port(port):
    print("Http Server Serving at port", port)
    server = ThreadingHTTPServer(("", port), Handler)
    server.serve_forever()

for port in PORTS:
    Thread(target=serve_on_port, args=[port]).start()
    
