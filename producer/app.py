import json
import time
import os
from datetime import datetime
from kafka import KafkaProducer
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_producer():
    ssl_context = {
        'security_protocol': 'SASL_SSL',
        'sasl_mechanism': 'PLAIN',
        'sasl_plain_username': 'client',
        'sasl_plain_password': 'client123',
        'ssl_check_hostname': False,
        'ssl_cafile': '/app/ssl/ca-cert',
        'ssl_certfile': '/app/ssl/client-cert',
        'ssl_keyfile': '/app/ssl/client-key',
    }
    
    brokers = os.getenv('KAFKA_BROKERS', 'kafka-1:9093,kafka-2:9095,kafka-3:9097')
    
    producer = KafkaProducer(
        bootstrap_servers=brokers.split(','),
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        key_serializer=lambda k: k.encode('utf-8') if k else None,
        **ssl_context
    )
    
    return producer

def main():
    topic = os.getenv('KAFKA_TOPIC', 'test-messages')
    
    logger.info(f"Starting producer for topic: {topic}")
    
    # Wait for Kafka to be ready
    time.sleep(30)
    
    try:
        producer = create_producer()
        logger.info("Producer created successfully")
        
        message_count = 0
        
        while True:
            message_count += 1
            
            message = {
                'id': message_count,
                'timestamp': datetime.now().isoformat(),
                'message': f'Hello from producer - message {message_count}',
                'source': 'kafka-producer'
            }
            
            try:
                future = producer.send(
                    topic,
                    key=f'key-{message_count}',
                    value=message
                )
                
                # Wait for message to be sent
                record_metadata = future.get(timeout=10)
                
                logger.info(f"Message {message_count} sent to {record_metadata.topic} "
                           f"partition {record_metadata.partition} "
                           f"offset {record_metadata.offset}")
                
            except Exception as e:
                logger.error(f"Error sending message {message_count}: {e}")
            
            time.sleep(5)
            
    except KeyboardInterrupt:
        logger.info("Producer interrupted by user")
    except Exception as e:
        logger.error(f"Producer error: {e}")
    finally:
        if 'producer' in locals():
            producer.close()
        logger.info("Producer closed")

if __name__ == "__main__":
    main()