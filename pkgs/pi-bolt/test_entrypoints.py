#!/usr/bin/env python3
"""Check compiled provider activation through the installed lead/child launchers."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread


class Catalog(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/v1/models":
            body = {"data": [{"id": "packaging-probe", "context_length": 8192}]}
        elif self.path == "/api/combos":
            body = {"combos": []}
        else:
            self.send_error(404)
            return
        data = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass


def main(*executables):
    server = ThreadingHTTPServer(("127.0.0.1", 0), Catalog)
    Thread(target=server.serve_forever, daemon=True).start()
    try:
        with tempfile.TemporaryDirectory() as directory:
            agent = Path(directory) / "agent"
            agent.mkdir()
            # Discovery must stay disabled while the compiled provider loads.
            (agent / "settings.json").write_text(json.dumps({"packages": ["/nonexistent/packaging-discovery-probe"]}))
            env = os.environ | {
                "PI_CODING_AGENT_DIR": str(agent),
                "OMNIROUTE_BASE_URL": f"http://127.0.0.1:{server.server_port}",
                "OMNIROUTE_API_KEY": "packaging-test",
                "PI_OFFLINE": "1",
            }
            cases = [
                (executable, args)
                for executable in executables
                for args in [[], ["--no-extensions", "-e", "builtin:mcp", "-e", "builtin:codemode"]]
            ]
            for executable, args in cases:
                result = subprocess.run(
                    [executable, *args, "--list-models", "packaging-probe"],
                    cwd=directory, env=env, text=True, capture_output=True, timeout=30,
                )
                output = result.stdout + result.stderr
                if result.returncode or "No models matching" in output or "packaging-probe" not in result.stdout or "Failed to load" in output:
                    raise AssertionError(f"{executable} {args}:\n{output}")
                print(f"PASS {Path(executable).name} {args}: compiled provider registered with discovery disabled")
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main(*sys.argv[1:])
