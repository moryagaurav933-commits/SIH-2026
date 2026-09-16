"""
Weather endpoints - Live GPS, Search, Open-Meteo & OpenWeatherMap with ICAR agro-advisory.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone, timedelta
from typing import Optional
import httpx

from app.db.session import get_db
from app.models.weather import WeatherCache
from app.schemas.schemas import WeatherResponse
from app.config import settings

router = APIRouter(prefix="/weather", tags=["Weather"])

DISTRICT_COORDS = {
    "UP001": (26.8467, 80.9462),  # Lucknow
    "UP002": (26.4499, 80.3319),  # Kanpur
    "UP003": (25.3176, 82.9739),  # Varanasi
    "MP001": (22.7196, 75.8577),  # Indore
    "HR001": (28.9931, 77.0151),  # Sonipat
    "DL001": (28.6139, 77.2090),  # Delhi
}

WMO_CODE_MAP = {
    0: ("Clear Sky", "साफ आसमान", "☀️"),
    1: ("Mainly Clear", "मुख्यतः साफ", "🌤️"),
    2: ("Partly Cloudy", "आंशिक बादल", "⛅"),
    3: ("Overcast", "घने बादल", "☁️"),
    45: ("Fog", "कोहरा", "🌫️"),
    48: ("Depositing Rime Fog", "घना कोहरा", "🌫️"),
    51: ("Light Drizzle", "हल्की बूंदाबांदी", "🌦️"),
    53: ("Moderate Drizzle", "बूंदाबांदी", "🌦️"),
    55: ("Dense Drizzle", "तेज बूंदाबांदी", "🌧️"),
    61: ("Slight Rain", "हल्की बारिश", "🌧️"),
    63: ("Moderate Rain", "मध्यम बारिश", "🌧️"),
    65: ("Heavy Rain", "भारी बारिश", "🌧️"),
    71: ("Slight Snow", "हल्की बर्फबारी", "🌨️"),
    80: ("Rain Showers", "बारिश की बौछारें", "🌦️"),
    81: ("Moderate Showers", "मध्यम बौछारें", "🌧️"),
    82: ("Violent Showers", "मूसलाधार बारिश", "⛈️"),
    95: ("Thunderstorm", "गरज के साथ बारिश", "⛈️"),
    96: ("Thunderstorm with Hail", "ओलावृष्टि के साथ तूफान", "⛈️"),
}


def _get_wmo_info(code: int):
    return WMO_CODE_MAP.get(code, ("Partly Cloudy", "आंशिक बादल", "⛅"))


def _generate_agri_advisory(temp_c: float, rain_mm: float, humidity: int):
    if rain_mm > 5.0:
        return (
            "भारी वर्षा की संभावना: खेतों में जल निकासी नाली साफ रखें। कीटनाशक व यूरिया का छिड़काव तुरंत रोकें।",
            "Rain alert: Ensure proper field drainage channels. Postpone fertilizer top-dressing and chemical sprays."
        )
    elif temp_c > 35.0:
        return (
            "उच्च तापमान: नमी बनाए रखने के लिए शाम के समय हल्की सिंचाई करें। मल्चिंग का उपयोग करें।",
            "High temperature alert: Apply light evening irrigation to prevent heat stress. Use mulch where possible."
        )
    elif humidity > 80:
        return (
            "उच्च आर्द्रता: फफूंद जनित रोगों (झुलसा/रतुआ) की संभावना। पत्तियों की नियमित निगरानी करें।",
            "High humidity: Elevated fungal risk (blight/rust). Inspect crop foliage regularly for symptoms."
        )
    else:
        return (
            "मौसम अनुकूल है: अनुशंसित पोषण प्रबंधन व समयबद्ध निराई-गुड़ाई जारी रखें।",
            "Favorable weather conditions: Proceed with scheduled crop nutrition and intercultural operations."
        )


@router.get("/live")
async def get_live_weather(
    lat: Optional[float] = Query(None, description="GPS Latitude"),
    lon: Optional[float] = Query(None, description="GPS Longitude"),
    q: Optional[str] = Query(None, description="City / District search query"),
    db: AsyncSession = Depends(get_db),
):
    """
    Get live weather with GPS coordinates or city search.
    Uses backend-secured API keys (OpenWeatherMap / IMD) or Open-Meteo with ICAR agro-advisories.
    """
    location_name = "Your Field Location"
    
    # 1. Handle city search if lat/lon not provided
    async with httpx.AsyncClient(timeout=10.0) as client:
        if (lat is None or lon is None) and q:
            try:
                geo_resp = await client.get(
                    f"https://geocoding-api.open-meteo.com/v1/search?name={q}&count=1&language=en&format=json"
                )
                if geo_resp.status_code == 200:
                    geo_data = geo_resp.json()
                    results = geo_data.get("results", [])
                    if results:
                        lat = results[0].get("latitude")
                        lon = results[0].get("longitude")
                        name = results[0].get("name", q)
                        admin = results[0].get("admin1", "")
                        location_name = f"{name}, {admin}" if admin else name
            except Exception as e:
                print(f"Geocoding error: {e}")

        # Default fallback coordinates (Lucknow)
        if lat is None or lon is None:
            lat, lon = (26.8467, 80.9462)
            location_name = "लखनऊ, उत्तर प्रदेश"

        # 2. Fetch live meteorological data
        apiKey = settings.OPENWEATHER_API_KEY or settings.WEATHER_API_KEY
        forecast_data = None
        source = "open-meteo"

        # Try OpenWeatherMap if secure key exists in server environment
        if apiKey:
            try:
                owm_resp = await client.get(
                    f"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&units=metric&appid={apiKey}"
                )
                if owm_resp.status_code == 200:
                    owm_data = owm_resp.json()
                    current_item = owm_data["list"][0]
                    temp = current_item["main"]["temp"]
                    humidity = current_item["main"]["humidity"]
                    wind_speed = current_item["wind"]["speed"] * 3.6
                    rain = current_item.get("rain", {}).get("3h", 0)
                    desc = current_item["weather"][0]["description"].title()
                    
                    forecast_5day = []
                    # Sample daily slices
                    for i in range(0, min(len(owm_data["list"]), 40), 8):
                        day_item = owm_data["list"][i]
                        dt_txt = day_item["dt_txt"].split(" ")[0]
                        forecast_5day.append({
                            "date": dt_txt,
                            "high": round(day_item["main"]["temp_max"]),
                            "low": round(day_item["main"]["temp_min"]),
                            "condition": day_item["weather"][0]["main"],
                            "condition_hi": "साफ" if "clear" in day_item["weather"][0]["description"] else "बादल",
                            "icon": "☀️" if "clear" in day_item["weather"][0]["description"] else "⛅",
                            "rain_mm": day_item.get("rain", {}).get("3h", 0),
                        })

                    advisory_hi, advisory_en = _generate_agri_advisory(temp, rain, humidity)
                    forecast_data = {
                        "location_name": location_name,
                        "latitude": lat,
                        "longitude": lon,
                        "current": {
                            "temp_c": round(temp),
                            "humidity": humidity,
                            "wind_kmh": round(wind_speed, 1),
                            "wind_direction": "SW",
                            "condition": desc,
                            "condition_hi": "आंशिक बादल",
                            "icon": "⛅",
                            "rain_prob": min(100, int(rain * 15)),
                            "uv_index": 6,
                        },
                        "forecast_5day": forecast_5day,
                        "advisory_hi": advisory_hi,
                        "advisory_en": advisory_en,
                    }
                    source = "openweathermap-secure-proxy"
            except Exception as e:
                print(f"OpenWeatherMap proxy error, falling back to Open-Meteo: {e}")

        # Fallback to Open-Meteo high-resolution model
        if not forecast_data:
            try:
                om_resp = await client.get(
                    f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,uv_index_max&timezone=auto"
                )
                if om_resp.status_code == 200:
                    data = om_resp.json()
                    current = data.get("current", {})
                    daily = data.get("daily", {})
                    
                    wmo_code = current.get("weather_code", 0)
                    cond_en, cond_hi, icon = _get_wmo_info(wmo_code)
                    
                    temp = current.get("temperature_2m", 28.0)
                    humidity = current.get("relative_humidity_2m", 65)
                    wind = current.get("wind_speed_10m", 12.0)
                    rain = current.get("precipitation", 0.0)
                    
                    days_hindi = ["आज", "कल", "परसों", "दिन 4", "दिन 5"]
                    forecast_5day = []
                    times = daily.get("time", [])
                    for i in range(min(5, len(times))):
                        d_code = daily.get("weather_code", [0])[i] if i < len(daily.get("weather_code", [])) else 0
                        d_en, d_hi, d_icon = _get_wmo_info(d_code)
                        forecast_5day.append({
                            "date": times[i],
                            "day_hi": days_hindi[i] if i < len(days_hindi) else f"दिन {i+1}",
                            "high": round(daily.get("temperature_2m_max", [30])[i]),
                            "low": round(daily.get("temperature_2m_min", [20])[i]),
                            "condition": d_en,
                            "condition_hi": d_hi,
                            "icon": d_icon,
                            "rain_mm": daily.get("precipitation_sum", [0])[i] if i < len(daily.get("precipitation_sum", [])) else 0,
                        })

                    advisory_hi, advisory_en = _generate_agri_advisory(temp, rain, humidity)
                    uv_val = daily.get("uv_index_max", [6])[0] if daily.get("uv_index_max") else 6
                    
                    forecast_data = {
                        "location_name": location_name,
                        "latitude": lat,
                        "longitude": lon,
                        "current": {
                            "temp_c": round(temp),
                            "humidity": round(humidity),
                            "wind_kmh": round(wind, 1),
                            "wind_direction": "SW",
                            "condition": cond_hi,
                            "condition_en": cond_en,
                            "icon": icon,
                            "rain_prob": int(daily.get("precipitation_probability_max", [20])[0]) if daily.get("precipitation_probability_max") else 20,
                            "uv_index": round(uv_val),
                        },
                        "forecast_5day": forecast_5day,
                        "advisory_hi": advisory_hi,
                        "advisory_en": advisory_en,
                    }
                    source = "open-meteo-live"
            except Exception as e:
                print(f"Open-Meteo live error: {e}")

        # If everything fails (total network outage), use demo generator
        if not forecast_data:
            forecast_data = _generate_demo_forecast("LIVE")
            forecast_data["location_name"] = location_name
            source = "offline-fallback"

    return {
        "status": "success",
        "source": source,
        "location": location_name,
        "latitude": lat,
        "longitude": lon,
        "cached_at": datetime.now(timezone.utc).isoformat(),
        "hours_left_in_cache": 12.0,
        "is_live": source != "offline-fallback",
        "data": forecast_data,
    }


@router.get("/forecast", response_model=WeatherResponse)
async def get_weather_forecast(
    district_code: str = Query(..., description="District code (e.g., 'UP001')"),
    db: AsyncSession = Depends(get_db),
):
    """Get weather forecast for a district code."""
    now = datetime.now(timezone.utc)
    
    result = await db.execute(
        select(WeatherCache)
        .where(WeatherCache.district_code == district_code)
        .order_by(WeatherCache.fetched_at.desc())
        .limit(1)
    )
    cache = result.scalar_one_or_none()

    if cache and cache.expires_at:
        expires_at = cache.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at > now:
            hours_left = (expires_at - now).total_seconds() / 3600.0
            return WeatherResponse(
                district_code=cache.district_code,
                district_name=cache.district_name,
                forecast_data=cache.forecast_data,
                compressed_payload=cache.compressed_payload,
                source=cache.source,
                fetched_at=cache.fetched_at,
                expires_at=cache.expires_at,
                hours_left_in_cache=hours_left
            )

    lat, lon = DISTRICT_COORDS.get(district_code, (26.8467, 80.9462))
    live_resp = await get_live_weather(lat=lat, lon=lon, q=None, db=db)
    forecast_data = live_resp["data"]
    source = live_resp["source"]

    expires = now + timedelta(hours=12)
    new_cache = WeatherCache(
        district_code=district_code,
        district_name=f"District {district_code}",
        forecast_data=forecast_data,
        source=source,
        fetched_at=now,
        expires_at=expires,
        compressed_payload=f"WX|{district_code}|{forecast_data['current']['temp_c']}C"
    )
    db.add(new_cache)
    await db.commit()
    await db.refresh(new_cache)
    
    return WeatherResponse(
        district_code=new_cache.district_code,
        district_name=new_cache.district_name,
        forecast_data=new_cache.forecast_data,
        compressed_payload=new_cache.compressed_payload,
        source=new_cache.source,
        fetched_at=new_cache.fetched_at,
        expires_at=new_cache.expires_at,
        hours_left_in_cache=12.0
    )


def _generate_demo_forecast(district_code: str) -> dict:
    """Generate realistic demo forecast data."""
    return {
        "location_name": "लखनऊ, उत्तर प्रदेश",
        "current": {
            "temp_c": 30,
            "humidity": 65,
            "wind_kmh": 12,
            "wind_direction": "SW",
            "condition": "आंशिक बादल",
            "condition_en": "Partly Cloudy",
            "icon": "⛅",
            "rain_prob": 20,
            "uv_index": 7,
        },
        "forecast_5day": [
            {"day_hi": "आज", "high": 31, "low": 24, "rain_mm": 5, "condition": "Light Rain", "condition_hi": "हल्की बारिश", "icon": "🌦️"},
            {"day_hi": "कल", "high": 30, "low": 23, "rain_mm": 12, "condition": "Moderate Rain", "condition_hi": "मध्यम बारिश", "icon": "🌧️"},
            {"day_hi": "परसों", "high": 29, "low": 23, "rain_mm": 8, "condition": "Light Rain", "condition_hi": "हल्की बारिश", "icon": "🌦️"},
            {"day_hi": "दिन 4", "high": 31, "low": 24, "rain_mm": 0, "condition": "Sunny", "condition_hi": "धूप", "icon": "☀️"},
            {"day_hi": "दिन 5", "high": 32, "low": 25, "rain_mm": 0, "condition": "Clear", "condition_hi": "साफ", "icon": "🌤️"},
        ],
        "advisory_hi": "कम बारिश के साथ फसल सिंचाई पर ध्यान दें। कीटनाशक छिड़काव से बचें।",
        "advisory_en": "Focus on crop irrigation with low rainfall expected. Avoid pesticide spraying.",
    }
