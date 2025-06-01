#!/usr/bin/env python3
"""
Three Pillars Demo Data Generator
===============================
Purpose: Generate realistic data scenarios for Technical Survival Strategy demonstration
Learning Value: Shows how Three Pillars handle various data conditions
"""

import time
import random
import pandas as pd
import psycopg2
from datetime import datetime, timedelta
import os

def connect_to_db():
    """Connect to PostgreSQL database"""
    return psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'localhost'),
        database=os.getenv('POSTGRES_DB', 'lakehouse'),
        user=os.getenv('POSTGRES_USER', 'demo'),
        password=os.getenv('POSTGRES_PASSWORD', 'demo123')
    )

def generate_sensor_data(num_records=100):
    """Generate realistic sensor data with quality issues for Guard pillar demonstration"""
    
    data = []
    locations = ['building_a', 'building_b', 'building_c', 'building_d']
    
    for i in range(num_records):
        base_time = datetime.now() - timedelta(hours=random.randint(0, 48))
        
        # Generate different data quality scenarios
        quality_scenario = random.choices(
            ['normal', 'temperature_anomaly', 'humidity_anomaly', 'sensor_failure'],
            weights=[85, 5, 5, 5]
        )[0]
        
        if quality_scenario == 'normal':
            temperature = round(random.uniform(20, 30), 1)
            humidity = round(random.uniform(40, 60), 1)
            status = 'NORMAL'
        elif quality_scenario == 'temperature_anomaly':
            temperature = round(random.uniform(80, 120), 1)  # Extreme temperature
            humidity = round(random.uniform(40, 60), 1)
            status = 'ANOMALY'
        elif quality_scenario == 'humidity_anomaly':
            temperature = round(random.uniform(20, 30), 1)
            humidity = round(random.uniform(95, 105), 1)  # Invalid humidity
            status = 'CRITICAL'
        else:  # sensor_failure
            temperature = -999.0  # Sensor failure indicator
            humidity = -999.0
            status = 'FAILURE'
        
        data.append({
            'id': i + 1,
            'sensor_id': f'sensor_{i%20 + 1:03d}',
            'temperature': temperature,
            'humidity': humidity,
            'measured_at': base_time.strftime('%Y-%m-%d %H:%M:%S'),
            'status': status,
            'location': random.choice(locations)
        })
    
    return data

def create_enhanced_sensor_readings():
    """Create enhanced sensor readings CSV with quality scenarios"""
    print("🔢 Generating Three Pillars demo data...")
    
    # Generate base sensor data
    sensor_data = generate_sensor_data(200)
    
    # Create DataFrame
    df = pd.DataFrame(sensor_data)
    
    # Save to seeds directory
    output_path = '/app/data/sensor_readings.csv'
    df.to_csv(output_path, index=False)
    
    print(f"✅ Generated {len(df)} sensor readings with quality scenarios")
    print(f"   Normal readings: {len(df[df['status'] == 'NORMAL'])}")
    print(f"   Anomaly readings: {len(df[df['status'] == 'ANOMALY'])}")
    print(f"   Critical readings: {len(df[df['status'] == 'CRITICAL'])}")
    print(f"   Failure readings: {len(df[df['status'] == 'FAILURE'])}")
    
    return output_path

def update_health_monitoring():
    """Update health monitoring with current status"""
    try:
        conn = connect_to_db()
        cur = conn.cursor()
        
        # Update system health with current timestamp
        cur.execute("""
            UPDATE monitoring.system_health 
            SET last_check = CURRENT_TIMESTAMP,
                details = details || '{"last_data_generation": "%s"}'::jsonb
            WHERE component = 'data_quality'
        """ % datetime.now().isoformat())
        
        conn.commit()
        cur.close()
        conn.close()
        
        print("✅ Updated health monitoring status")
        
    except Exception as e:
        print(f"⚠️ Could not update health monitoring: {e}")

def main():
    """Main execution function"""
    print("🚀 Three Pillars Demo Data Generator Starting...")
    print("=" * 50)
    
    # Wait for database to be ready
    max_retries = 10
    for attempt in range(max_retries):
        try:
            conn = connect_to_db()
            conn.close()
            print("✅ Database connection successful")
            break
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"⏳ Waiting for database... (attempt {attempt + 1}/{max_retries})")
                time.sleep(5)
            else:
                print(f"❌ Could not connect to database after {max_retries} attempts")
                return
    
    # Generate demo data
    create_enhanced_sensor_readings()
    
    # Update health monitoring
    update_health_monitoring()
    
    print("=" * 50)
    print("🎉 Three Pillars demo data generation complete!")
    print("📊 Ready for dbt transformations and quality validation")
    print("🔍 Monitor results in Grafana dashboard")

if __name__ == "__main__":
    main()
