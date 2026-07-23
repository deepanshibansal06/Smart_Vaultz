from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

class CustomHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

if __name__ == '__main__':
    web_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(web_dir)
    port = 8085
    for p in range(8085, 8095):
        try:
            server_address = ('', p)
            httpd = HTTPServer(server_address, CustomHandler)
            print(f"Smart Vaultz Web Application serving at http://localhost:{p}")
            httpd.serve_forever()
            break
        except OSError:
            continue

