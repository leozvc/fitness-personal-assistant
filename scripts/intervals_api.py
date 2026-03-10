import argparse
import requests
import json
import os
import base64
from datetime import datetime, timedelta

# Load configuration
def load_config():
    config_path = os.path.join(os.path.dirname(__file__), '../config.json')
    if not os.path.exists(config_path):
        # Fallback to template if config.json doesn't exist (for initial setup/testing)
        config_path = os.path.join(os.path.dirname(__file__), '../assets/config_template.json')
    
    with open(config_path, 'r') as f:
        return json.load(f)

CONFIG = load_config()
API_KEY = CONFIG['intervals_icu']['api_key']
ATHLETE_ID = CONFIG['intervals_icu']['athlete_id']
BASE_URL = "https://intervals.icu/api/v1"

# Basic Auth
auth = ( "API_KEY", API_KEY)

def get_athlete_summary():
    """Get athlete summary (fitness, fatigue, form etc.)"""
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/athlete-summary"
    response = requests.get(url, auth=auth)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching athlete summary: {response.status_code} - {response.text}")
        return None

def get_activities(days=30):
    """Get activities for the last N days"""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/activities"
    params = {
        'oldest': start_date.strftime('%Y-%m-%d'),
        'newest': end_date.strftime('%Y-%m-%d')
    }
    
    response = requests.get(url, auth=auth, params=params)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching activities: {response.status_code} - {response.text}")
        return None

def get_wellness(date=None):
    """Get wellness data for a specific date (default today)"""
    if not date:
        date = datetime.now().strftime('%Y-%m-%d')
    
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/wellness/{date}"
    response = requests.get(url, auth=auth)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching wellness data: {response.status_code} - {response.text}")
        return None

def get_events(start_date, end_date):
    """Get calendar events (workouts) for a date range"""
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/events"
    params = {
        'oldest': start_date,
        'newest': end_date
    }
    
    response = requests.get(url, auth=auth, params=params)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching events: {response.status_code} - {response.text}")
        return None

def create_workout(date, name, description, category="WORKOUT", type_="Ride"):
    """Create a workout event on the calendar"""
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/events"
    data = {
        "category": category,
        "start_date_local": f"{date}T08:00:00", # Default to 8 AM
        "name": name,
        "description": description,
        "type": type_
    }
    
    response = requests.post(url, auth=auth, json=data)
    if response.status_code == 200:
        print(f"Successfully created workout: {name} on {date}")
        return response.json()
    else:
        print(f"Error creating workout: {response.status_code} - {response.text}")
        return None

def delete_event(event_id):
    """Delete an event by ID"""
    url = f"{BASE_URL}/athlete/{ATHLETE_ID}/events/{event_id}"
    response = requests.delete(url, auth=auth)
    if response.status_code == 200 or response.status_code == 204:
        print(f"Successfully deleted event: {event_id}")
        return True
    else:
        print(f"Error deleting event {event_id}: {response.status_code} - {response.text}")
        return False

def get_summary_data():
    """Aggregate summary data for the assistant"""
    summary = get_athlete_summary()
    activities = get_activities(days=7) # Last 7 days
    wellness = get_wellness()
    
    data = {
        "athlete_summary": summary,
        "recent_activities": activities,
        "today_wellness": wellness,
        "timestamp": datetime.now().isoformat()
    }
    
    print(json.dumps(data, indent=2))
    return data

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intervals.icu API Client")
    parser.add_argument("--action", required=True, choices=['get_summary_data', 'get_activities', 'create_workout', 'get_events', 'delete_event'], help="Action to perform")
    parser.add_argument("--date", help="Date for creating workout (YYYY-MM-DD)")
    parser.add_argument("--name", help="Workout name")
    parser.add_argument("--desc", help="Workout description")
    parser.add_argument("--days", type=int, default=30, help="Days to look back for activities")
    parser.add_argument("--start_date", help="Start date for events (YYYY-MM-DD)")
    parser.add_argument("--end_date", help="End date for events (YYYY-MM-DD)")
    parser.add_argument("--event_id", help="Event ID to delete")

    args = parser.parse_args()

    if args.action == "get_summary_data":
        get_summary_data()
    elif args.action == "get_activities":
        activities = get_activities(args.days)
        print(json.dumps(activities, indent=2))
    elif args.action == "create_workout":
        if not args.date or not args.name or not args.desc:
            print("Error: --date, --name, and --desc are required for create_workout")
        else:
            create_workout(args.date, args.name, args.desc)
    elif args.action == "get_events":
        if not args.start_date or not args.end_date:
            print("Error: --start_date and --end_date are required for get_events")
        else:
            events = get_events(args.start_date, args.end_date)
            print(json.dumps(events, indent=2))
    elif args.action == "delete_event":
        if not args.event_id:
            print("Error: --event_id is required for delete_event")
        else:
            delete_event(args.event_id)
