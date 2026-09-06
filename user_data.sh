#!/bin/bash
set -euxo pipefail

dnf install -y python3

mkdir -p /opt/imds-lab

cat > /opt/imds-lab/app.py <<'PYEOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

IMDS = "http://169.254.169.254/latest"


class Handler(BaseHTTPRequestHandler):
    def send_body(self, status, body, content_type="text/plain"):
        if isinstance(body, str):
            body = body.encode()

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def proxy_get(self, url, headers=None):
        request = Request(
            url,
            headers=headers or {},
            method="GET",
        )

        try:
            with urlopen(request, timeout=3) as response:
                self.send_body(
                    response.status,
                    response.read(),
                    response.headers.get_content_type() or "text/plain",
                )
        except HTTPError as error:
            self.send_body(error.code, error.read())
        except URLError as error:
            self.send_body(502, f"Request failed: {error}\n")
        except Exception as error:
            self.send_body(502, f"Unexpected error: {error}\n")

    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path == "/":
            self.send_body(
                200,
                """IMDS lab

Endpoints:
  /health
  /legacy
  /v2
  /fetch?url=https://example.com

/legacy uses an IMDSv1-style request.
/v2 uses an IMDSv2 token.
/fetch is intentionally vulnerable to SSRF for this sandbox lab.
""",
            )
            return

        if parsed.path == "/health":
            self.send_body(200, "ok\n")
            return

        if parsed.path == "/legacy":
            self.proxy_get(f"{IMDS}/meta-data/instance-id")
            return

        if parsed.path == "/v2":
            try:
                token_request = Request(
                    f"{IMDS}/api/token",
                    data=b"",
                    headers={
                        "X-aws-ec2-metadata-token-ttl-seconds": "21600"
                    },
                    method="PUT",
                )

                with urlopen(token_request, timeout=3) as response:
                    token = response.read().decode()

                self.proxy_get(
                    f"{IMDS}/meta-data/instance-id",
                    headers={
                        "X-aws-ec2-metadata-token": token
                    },
                )
            except HTTPError as error:
                self.send_body(error.code, error.read())
            except Exception as error:
                self.send_body(502, f"IMDSv2 request failed: {error}\n")
            return

        if parsed.path == "/fetch":
            query = parse_qs(parsed.query)
            target = query.get("url", [None])[0]

            if not target:
                self.send_body(400, "Missing url parameter\n")
                return

            target_url = urlparse(target)

            if target_url.scheme not in ("http", "https"):
                self.send_body(400, "Only http and https URLs are allowed\n")
                return

            # Intentionally vulnerable for the lab:
            # the server performs a GET to a user-controlled URL.
            self.proxy_get(target)
            return

        self.send_body(404, "Not found\n")


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
PYEOF

cat > /etc/systemd/system/imds-lab.service <<'UNITEOF'
[Unit]
Description=Deliberately vulnerable IMDS lab application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/python3 /opt/imds-lab/app.py
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
UNITEOF

chown -R ec2-user:ec2-user /opt/imds-lab
systemctl daemon-reload
systemctl enable --now imds-lab.service
