#!/usr/bin/env python3
"""Serve the web build over HTTPS on the local network, for trying the game on a
phone or tablet on the same Wi-Fi.

    python3 tools/serve_https.py            # serves build/web on port 8443

Why HTTPS: the Godot web engine only starts in a "secure context". The same
computer (http://localhost) counts as secure; any other device on the network needs
https://. The certificate is made here, for this machine only, so the browser
will warn that it is not trusted. That is expected for a private test: choose
"Show Details" / "Advanced" and continue to the site.

The certificate and key live in build/.local-https/ (never committed) and are
remade when the machine's network address changes. Nothing is sent anywhere.
"""
import http.server
import os
import socket
import ssl
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "build", "web")
CERT_DIR = os.path.join(ROOT, "build", ".local-https")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8443


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))    # no packet is sent; just picks the Wi-Fi interface
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def ensure_cert(ip):
    os.makedirs(CERT_DIR, exist_ok=True)
    cert, key, stamp = (os.path.join(CERT_DIR, n) for n in ("cert.pem", "key.pem", "address.txt"))
    current = open(stamp).read().strip() if os.path.exists(stamp) else ""
    if not (os.path.exists(cert) and os.path.exists(key) and current == ip):
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "60",
             "-keyout", key, "-out", cert, "-subj", "/CN=TATO local test",
             "-addext", "subjectAltName=IP:%s,IP:127.0.0.1,DNS:localhost" % ip],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        os.chmod(key, 0o600)
        with open(stamp, "w") as f:
            f.write(ip)
    return cert, key


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB, **kwargs)

    def end_headers(self):
        # always fetch the newest build while testing
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stdout.write("%s %s\n" % (self.address_string(), fmt % args))
        sys.stdout.flush()


def main():
    if not os.path.exists(os.path.join(WEB, "index.html")):
        sys.exit("build/web/index.html is missing: run tools/build.sh web first")
    ip = lan_ip()
    cert, key = ensure_cert(ip)
    Handler.extensions_map[".wasm"] = "application/wasm"
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    print("TATO! web build on https://%s:%d  (this computer: https://localhost:%d)" % (ip, PORT, PORT), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
