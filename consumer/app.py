import json
import time
import os
from kafka import KafkaConsumer
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_consumer():
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
    topic = os.getenv('KAFKA_TOPIC', 'test-messages')
    
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=brokers.split(','),
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='message-consumer-group',
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        key_deserializer=lambda k: k.decode('utf-8') if k else None,
        **ssl_context
    )
    
    return consumer

def main():
    topic = os.getenv('KAFKA_TOPIC', 'test-messages')
    
    logger.info(f"Starting consumer for topic: {topic}")
    
    # Wait for Kafka to be ready
    time.sleep(35)
    
    try:
        consumer = create_consumer()
        logger.info("Consumer created successfully")
        
        logger.info("Waiting for messages...")
        
        for message in consumer:
            try:
                logger.info(f"Received message:")
                logger.info(f"  Topic: {message.topic}")
                logger.info(f"  Partition: {message.partition}")
                logger.info(f"  Offset: {message.offset}")
                logger.info(f"  Key: {message.key}")
                logger.info(f"  Value: {json.dumps(message.value, indent=2)}")
                logger.info(f"  Timestamp: {message.timestamp}")
                logger.info("-" * 50)
                
                # Print to stdout for visibility
                print(f"MESSAGE RECEIVED:")
                print(f"Topic: {message.topic} | Partition: {message.partition} | Offset: {message.offset}")
                print(f"Key: {message.key}")
                print(f"Content: {json.dumps(message.value, indent=2)}")
                print("=" * 60)
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                
    except KeyboardInterrupt:
        logger.info("Consumer interrupted by user")
    except Exception as e:
        logger.error(f"Consumer error: {e}")
    finally:
        if 'consumer' in locals():
            consumer.close()
        logger.info("Consumer closed")

if __name__ == "__main__":
    main()