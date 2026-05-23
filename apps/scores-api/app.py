"""NBA Scores API — a simple Flask app for demonstrating Nelm deployments."""

import os
import json
from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "v1")
WELCOME_MESSAGE = os.environ.get("WELCOME_MESSAGE", "NBA Live Scores")

SCORES = [
    {"game_id": 1, "home": "Lakers", "away": "Celtics", "home_score": 112, "away_score": 108, "quarter": "Final", "arena": "Crypto.com Arena"},
    {"game_id": 2, "home": "Warriors", "away": "Nuggets", "home_score": 98, "away_score": 105, "quarter": "4th", "arena": "Chase Center"},
    {"game_id": 3, "home": "Bucks", "away": "Heat", "home_score": 87, "away_score": 91, "quarter": "3rd", "arena": "Fiserv Forum"},
]

PLAY_BY_PLAY = [
    {"game_id": 1, "time": "0:42", "action": "LeBron James drives for the layup", "player": "LeBron James"},
    {"game_id": 1, "time": "1:15", "action": "Jayson Tatum hits the three-pointer", "player": "Jayson Tatum"},
    {"game_id": 2, "time": "2:30", "action": "Stephen Curry with the step-back three", "player": "Stephen Curry"},
]


@app.route("/")
def index():
    return jsonify({
        "service": "scores-api",
        "version": APP_VERSION,
        "message": WELCOME_MESSAGE,
        "endpoints": ["/scores", "/health"],
    })


@app.route("/scores")
def scores():
    data = {"version": APP_VERSION, "scores": SCORES}
    if APP_VERSION == "v2":
        data["play_by_play"] = PLAY_BY_PLAY
    return jsonify(data)


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "version": APP_VERSION})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
