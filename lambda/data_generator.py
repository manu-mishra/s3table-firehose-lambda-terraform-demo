import boto3
import json
import time
import random
import os

firehose = boto3.client('firehose')
STREAM_NAME = os.environ.get('STREAM_NAME', 'firehosetos3demo')

# Define 10 sensors with their locations
SENSORS = [
    {"id": "sensor-001", "location": "warehouse-a"},
    {"id": "sensor-002", "location": "warehouse-a"},
    {"id": "sensor-003", "location": "warehouse-b"},
    {"id": "sensor-004", "location": "warehouse-b"},
    {"id": "sensor-005", "location": "warehouse-c"},
    {"id": "sensor-006", "location": "warehouse-c"},
    {"id": "sensor-007", "location": "office"},
    {"id": "sensor-008", "location": "office"},
    {"id": "sensor-009", "location": "datacenter"},
    {"id": "sensor-010", "location": "datacenter"}
]

def lambda_handler(event, context):
    end_time = time.time() + 50
    records_sent = 0
    sensor_index = 0
    
    print(f"Starting data generation for stream: {STREAM_NAME}")
    
    while time.time() < end_time:
        # Batch 200 records together (Firehose supports up to 500 records per batch)
        batch = []
        for _ in range(200):
            sensor = SENSORS[sensor_index]
            
            data = {
                "sensor_id": sensor["id"],
                "timestamp": int(time.time()),
                "location": sensor["location"],
                "temperature": round(random.uniform(18.0, 28.0), 2),
                "humidity": round(random.uniform(40.0, 80.0), 2),
                "pressure": round(random.uniform(1000.0, 1020.0), 2)
            }
            
            batch.append({'Data': json.dumps(data) + '\n'})
            sensor_index = (sensor_index + 1) % len(SENSORS)
        
        # Send batch in one API call
        response = firehose.put_record_batch(
            DeliveryStreamName=STREAM_NAME,
            Records=batch
        )
        
        records_sent += len(batch)
        
        # Check for failures
        if response['FailedPutCount'] > 0:
            print(f"Warning: {response['FailedPutCount']} records failed in batch")
        
        time.sleep(1)
    
    print(f"Completed: Sent {records_sent} records from {len(SENSORS)} sensors")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Sent {records_sent} records from {len(SENSORS)} sensors')
    }


