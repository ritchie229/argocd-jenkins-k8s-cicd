from flask import Flask, render_template
import os

app = Flask(__name__)

@app.route("/")
def index():
    app_name = os.getenv("APP_NAME", "Argocd-Jenkins-K8s")
    version = os.getenv("APP_VERSION", "dev")
    return render_template("index.html", app_name=app_name, version=version)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

