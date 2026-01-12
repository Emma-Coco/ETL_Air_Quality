from fastapi import FastAPI, HTTPException
import requests
import sqlite3
from collections import defaultdict
from datetime import date

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

app = FastAPI(title="Air Quality ETL API")

DB_PATH = "air_quality.db"
OPEN_METEO_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"


# --------------------------------------------------
# DATABASE INITIALIZATION
# --------------------------------------------------

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS air_quality_daily (
            date TEXT PRIMARY KEY,
            pm2_5_avg REAL,
            pm10_avg REAL,
            nitrogen_dioxide_avg REAL
        )
    """)

    conn.commit()
    conn.close()


init_db()


# --------------------------------------------------
# CORE ETL LOGIC
# --------------------------------------------------

def fetch_hourly_air_quality(latitude: float, longitude: float):
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "hourly": "pm2_5,pm10,nitrogen_dioxide",
        "timezone": "UTC"
    }

    response = requests.get(OPEN_METEO_URL, params=params)
    response.raise_for_status()

    return response.json()["hourly"]


def compute_daily_aggregates(hourly_data):
    daily_values = defaultdict(lambda: {
        "pm2_5": [],
        "pm10": [],
        "nitrogen_dioxide": []
    })

    for i, timestamp in enumerate(hourly_data["time"]):
        date = timestamp.split("T")[0]
        daily_values[date]["pm2_5"].append(hourly_data["pm2_5"][i])
        daily_values[date]["pm10"].append(hourly_data["pm10"][i])
        daily_values[date]["nitrogen_dioxide"].append(
            hourly_data["nitrogen_dioxide"][i]
        )

    aggregated = []

    for date, values in daily_values.items():
        aggregated.append({
            "date": date,
            "pm2_5_avg": round(sum(values["pm2_5"]) / len(values["pm2_5"]), 2),
            "pm10_avg": round(sum(values["pm10"]) / len(values["pm10"]), 2),
            "nitrogen_dioxide_avg": round(
                sum(values["nitrogen_dioxide"]) / len(values["nitrogen_dioxide"]), 2
            )
        })

    return aggregated


# --------------------------------------------------
# HEALTH CHECK
# --------------------------------------------------

@app.get("/health")
def health_check():
    return {"status": "ok"}


# --------------------------------------------------
# ETL ENDPOINTS
# --------------------------------------------------

@app.get("/extract")
def extract_air_quality(
    latitude: float = 48.8566,
    longitude: float = 2.3522
):
    return fetch_hourly_air_quality(latitude, longitude)


# --------------------------------------------------
# TRANSFORM
# --------------------------------------------------

@app.get("/transform")
def transform_air_quality(
    latitude: float = 48.8566,
    longitude: float = 2.3522
):
    hourly = fetch_hourly_air_quality(latitude, longitude)

    return [
        {
            "datetime": timestamp,
            "pm2_5": hourly["pm2_5"][i],
            "pm10": hourly["pm10"][i],
            "nitrogen_dioxide": hourly["nitrogen_dioxide"][i]
        }
        for i, timestamp in enumerate(hourly["time"])
    ]

# --------------------------------------------------
# AGGREGATE (DAILY)
# --------------------------------------------------

@app.get("/aggregate-daily")
def aggregate_daily(
    latitude: float = 48.8566,
    longitude: float = 2.3522
):
    hourly = fetch_hourly_air_quality(latitude, longitude)
    return compute_daily_aggregates(hourly)


# --------------------------------------------------
# LOAD (STORE INTO SQLITE)
# --------------------------------------------------

@app.post("/load")
def load_data(
    latitude: float = 48.8566,
    longitude: float = 2.3522
):
    hourly = fetch_hourly_air_quality(latitude, longitude)
    aggregated_data = compute_daily_aggregates(hourly)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    for row in aggregated_data:
        cursor.execute("""
            INSERT OR REPLACE INTO air_quality_daily
            (date, pm2_5_avg, pm10_avg, nitrogen_dioxide_avg)
            VALUES (?, ?, ?, ?)
        """, (
            row["date"],
            row["pm2_5_avg"],
            row["pm10_avg"],
            row["nitrogen_dioxide_avg"]
        ))

    conn.commit()
    conn.close()

    return {
        "status": "success",
        "rows_inserted": len(aggregated_data)
    }


# --------------------------------------------------
# READ API (FOR FRONTEND / USERS) FROM DB
# --------------------------------------------------

@app.get("/air-quality/daily")
def get_air_quality_daily(limit: int = 5):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT date, pm2_5_avg, pm10_avg, nitrogen_dioxide_avg
        FROM air_quality_daily
        ORDER BY date DESC
        LIMIT ?
    """, (limit,))

    rows = cursor.fetchall()
    conn.close()

    return [
        {
            "date": row[0],
            "pm2_5_avg": row[1],
            "pm10_avg": row[2],
            "nitrogen_dioxide_avg": row[3]
        }
        for row in reversed(rows)
    ]

@app.get("/air-quality/today")
def get_today_air_quality():
    today = date.today().isoformat()

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT date, pm2_5_avg, pm10_avg, nitrogen_dioxide_avg
        FROM air_quality_daily
        WHERE date = ?
    """, (today,))

    row = cursor.fetchone()
    conn.close()

    if row is None:
        raise HTTPException(
            status_code=404,
            detail="No air quality data available for today"
        )

    return {
        "date": row[0],
        "pm2_5_avg": row[1],
        "pm10_avg": row[2],
        "nitrogen_dioxide_avg": row[3]
    }
