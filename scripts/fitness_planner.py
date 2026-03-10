import argparse
import json
import os
import sys
from datetime import datetime, timedelta

# Import intervals_api module
sys.path.append(os.path.dirname(__file__))
import intervals_api

def generate_plan(goal="endurance", days=7, sport_type="Ride"):
    """
    Generate a simple fitness plan based on goal and current status.
    This is a basic logic placeholder. In a real AI agent scenario, 
    the LLM would use the data fetched here to reason and generate the plan.
    """
    
    # 1. Fetch current context
    print("Fetching athlete data...")
    summary_data = intervals_api.get_summary_data()
    
    athlete_summary = summary_data.get('athlete_summary', [])
    current_fitness = 0
    current_fatigue = 0
    current_form = 0
    
    if athlete_summary:
        # Assuming the first entry is the user
        user_summary = athlete_summary[0]
        current_fitness = user_summary.get('fitness', 0)
        current_fatigue = user_summary.get('fatigue', 0)
        current_form = user_summary.get('form', 0)

    print(f"Current Status - Fitness (CTL): {current_fitness}, Fatigue (ATL): {current_fatigue}, Form (TSB): {current_form}")
    
    # 2. Plan Logic (Simplistic Rule-Based)
    plan = []
    start_date = datetime.now() + timedelta(days=1) # Start tomorrow
    
    print(f"\nGenerating {goal} plan for the next {days} days...")

    for i in range(days):
        day_date = start_date + timedelta(days=i)
        date_str = day_date.strftime('%Y-%m-%d')
        weekday = day_date.weekday() # 0=Monday, 6=Sunday
        
        workout = None
        
        # Plan Templates
        if goal == "endurance" and sport_type == "Ride":
            if weekday == 0: # Mon: Rest
                workout = {"name": "Rest Day", "desc": "Active recovery or full rest.", "category": "NOTE", "type": "Note"}
            elif weekday == 1: # Tue: Intervals
                workout = {"name": "Z4 Intervals", "desc": "Warmup 15m\n4x 8m Z4 (Threshold) / 4m Z1\nCooldown 15m", "category": "WORKOUT", "type": "Ride"}
            elif weekday == 2: # Wed: Z2 Endurance
                workout = {"name": "Z2 Endurance", "desc": "60m Z2 Steady ride.", "category": "WORKOUT", "type": "Ride"}
            elif weekday == 3: # Thu: Sweet Spot
                workout = {"name": "Sweet Spot", "desc": "Warmup 15m\n3x 12m Sweet Spot (88-94% FTP) / 5m Z1\nCooldown 15m", "category": "WORKOUT", "type": "Ride"}
            elif weekday == 4: # Fri: Rest/Easy
                workout = {"name": "Easy Spin", "desc": "30m Z1 Recovery spin.", "category": "WORKOUT", "type": "Ride"}
            elif weekday == 5: # Sat: Long Ride
                workout = {"name": "Long Z2 Ride", "desc": "3-4h Z2 Endurance ride.", "category": "WORKOUT", "type": "Ride"}
            elif weekday == 6: # Sun: Tempo/Group
                workout = {"name": "Tempo Ride", "desc": "90m Z3 Tempo or Group Ride.", "category": "WORKOUT", "type": "Ride"}
        
        elif goal == "tennis_fitness" or (goal == "endurance" and sport_type != "Ride"):
            # Template for Tennis/General Fitness (Run + Gym)
            if weekday == 0: # Mon: Rest
                workout = {"name": "Rest Day", "desc": "Active recovery.", "category": "NOTE", "type": "Note"}
            elif weekday == 1: # Tue: Sprints/Footwork
                workout = {"name": "Interval Runs", "desc": "Warmup 10m\n10x 1m Fast / 1m Slow\nCooldown 10m", "category": "WORKOUT", "type": "Run"}
            elif weekday == 2: # Wed: Strength
                workout = {"name": "Strength Training", "desc": "Full body strength session (Squats, Deadlifts, Core).", "category": "WORKOUT", "type": "WeightTraining"}
            elif weekday == 3: # Thu: Tennis Drill
                workout = {"name": "Tennis Practice", "desc": "Drills or hitting session.", "category": "WORKOUT", "type": "Tennis"}
            elif weekday == 4: # Fri: Active Recovery
                workout = {"name": "Mobility/Yoga", "desc": "Stretching and mobility work.", "category": "WORKOUT", "type": "Yoga"}
            elif weekday == 5: # Sat: Match
                workout = {"name": "Tennis Match", "desc": "Match play or competitive sets.", "category": "WORKOUT", "type": "Tennis"}
            elif weekday == 6: # Sun: Long Run
                workout = {"name": "Aerobic Run", "desc": "45-60m Steady Z2 Run.", "category": "WORKOUT", "type": "Run"}

        # Check Form to adjust
        if current_form < -30:
            # Too tired
            if workout and workout['category'] == 'WORKOUT':
                 workout = {"name": "Recovery Instead", "desc": "Form is too low. Rest or light walk.", "category": "NOTE", "type": "Note"}

        if workout:
            plan.append({
                "date": date_str,
                "name": workout['name'],
                "description": workout['desc'],
                "category": workout['category'],
                "type": workout.get('type', 'Workout')
            })

    # 3. Output Plan
    print("\nGenerated Plan:")
    print(json.dumps(plan, indent=2))
    
    return plan

def apply_plan(plan):
    """Upload the generated plan to Intervals.icu"""
    print("\nUploading plan to calendar...")
    for item in plan:
        intervals_api.create_workout(
            date=item['date'],
            name=item['name'],
            description=item['description'],
            category=item['category'],
            type_=item.get('type', 'Ride') # Pass type explicitly
        )

def clear_future_plan(days=7):
    """Clear existing planned workouts for the next N days to avoid duplicates"""
    print("\nClearing existing future plans...")
    start_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
    end_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
    
    events = intervals_api.get_events(start_date, end_date)
    if not events:
        print("No existing events found.")
        return

    count = 0
    for event in events:
        # Only delete planned workouts (category WORKOUT) that are not completed (no activity_id usually, but here we just check category)
        # Be careful not to delete completed activities if they appear here (get_events returns both)
        # Intervals API: 'category': 'WORKOUT' usually implies planned. Completed ones might be tied to activities.
        # Safer check: if it doesn't have an associated activity or is in the future.
        
        # In Intervals.icu, future planned workouts are events.
        if event.get('category') in ['WORKOUT', 'NOTE'] and not event.get('activity_id'):
             print(f"Deleting event: {event.get('name')} ({event.get('start_date_local')})")
             intervals_api.delete_event(event.get('id'))
             count += 1
    
    print(f"Cleared {count} existing events.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fitness Planner")
    parser.add_argument("--action", required=True, choices=['generate_plan', 'apply_plan', 'clear_plan'], help="Action to perform")
    parser.add_argument("--goal", default="endurance", help="Fitness goal (endurance, strength, tennis_fitness)")
    parser.add_argument("--days", type=int, default=7, help="Number of days to plan")
    parser.add_argument("--sport_type", default="Ride", help="Main sport type (Ride, Run, Tennis)")
    parser.add_argument("--auto_apply", action="store_true", help="Automatically upload generated plan")

    args = parser.parse_args()

    if args.action == "generate_plan":
        # Optional: Clear before generating if desired, or user can call clear_plan separately.
        # For safety, let's just generate. 
        # But if auto_apply is on, maybe we should clear first? 
        # Let's keep it manual or implicit in apply? 
        # For now, let's adding clear logic inside apply_plan is risky if not asked.
        # User asked to clear.
        pass
        
        plan = generate_plan(args.goal, args.days, args.sport_type)
        if args.auto_apply:
            clear_future_plan(args.days)
            apply_plan(plan)
            
    elif args.action == "apply_plan":
        clear_future_plan(args.days)
        plan = generate_plan(args.goal, args.days, args.sport_type)
        apply_plan(plan)
        
    elif args.action == "clear_plan":
        clear_future_plan(args.days)
