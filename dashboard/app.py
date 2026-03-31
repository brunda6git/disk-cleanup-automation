from flask import Flask, render_template
import subprocess
import os

app = Flask(__name__)

# SET YOUR EXACT LOG FILE PATH
LOG_FILE = os.path.join(os.path.dirname(__file__), "../logs/disk_cleanup.log")


# Get disk usage
def get_disk_usage():
    try:
        usage = subprocess.check_output("df / | awk 'NR==2 {print $5}'", shell=True)
        return int(usage.decode().strip().replace("%", ""))
    except:
        return 0


# Get last logs (latest first)
def get_logs(limit=20):
    try:
        if not os.path.exists(LOG_FILE):
            return ["Log file not found"]

        with open(LOG_FILE, "r") as f:
            logs = f.readlines()

        logs = logs[-limit:][::-1]   # latest logs on top

        return logs if logs else ["No logs available"]

    except Exception as e:
        return [f"Error reading logs: {str(e)}"]


# Dashboard route
@app.route("/")
def dashboard():
    usage = get_disk_usage()
    logs = get_logs()
    return render_template("index.html", usage=usage, logs=logs)


# Full logs page
@app.route("/logs")
def all_logs():
    try:
        if not os.path.exists(LOG_FILE):
            return ["Log file not found"]

        with open(LOG_FILE, "r") as f:
            logs = f.readlines()

        logs = logs[::-1]   # newest first

        return render_template("logs.html", logs=logs)

    except Exception as e:
        return [f"Error loading logs: {str(e)}"]


# Run app
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)
