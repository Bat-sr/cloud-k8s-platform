"""Small demo web app used to practise Docker, Kubernetes and AWS deployment."""
import os
import socket
import time

from flask import Flask, jsonify

app = Flask(__name__)
START_TIME = time.time()
VERSION = os.getenv("APP_VERSION", "0.1.0")


@app.route("/")
def index():
    # Shows which container (pod) answered. Useful later to see load balancing.
    return (
        "<h1>Cloud K8s Platform demo</h1>"
        f"<p>Version: {VERSION}</p>"
        f"<p>Served by: {socket.gethostname()}</p>"
        '<p>Try <a href="/health">/health</a> and <a href="/api/info">/api/info</a></p>'
    )


@app.route("/health")
def health():
    # Kubernetes will call this to check the app is alive (probes).
    return jsonify(status="ok"), 200


@app.route("/api/info")
def info():
    return jsonify(
        app="cloud-k8s-demo",
        version=VERSION,
        hostname=socket.gethostname(),
        uptime_seconds=round(time.time() - START_TIME, 1),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
