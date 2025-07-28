# Kafka SSL Cluster with Python Producer & Consumer

A fully Dockerized Apache Kafka setup with end-to-end SSL encryption and SASL/PLAIN authentication, powered by a Python-based producer and consumer.

This project sets up a **secure Kafka cluster** with:
- SSL/TLS & SASL Authentication
- Docker Compose Orchestration
- Python Kafka Clients (Producer & Consumer)
- Automated SSL Certificate Generation


## Services Overview

| Service           | Description                                               |
|------------------|-----------------------------------------------------------|
| `ssl-setup`       | Generates all keystore/truststore and JAAS configs       |
| `kafka-1/2/3`     | 3-node Kafka cluster with SSL & SASL/PLAIN auth      |
| `message-producer`| Python app sending JSON messages to Kafka topic          |
| `message-consumer`| Python app consuming messages securely from Kafka        |


## Getting Started

### 1. Clone the Repo

```bash
git clone https://github.com/RazorWrecktor/kafka-ssl-cluster.git
cd kafka-ssl-cluster
```

### 2. Start the Cluster

```bash
docker-compose up --build
```

This will:
- Build Python producer & consumer
- Generate SSL credentials
- Spin up a 3-node Kafka cluster with TLS/SASL
- Start producer and consumer apps


## Data Flow

```text
message-producer --> Kafka Topic ('test-messages') --> message-consumer
```

Every 5 seconds, the producer sends a structured JSON message:
```json
{
  "id": 1,
  "timestamp": "2025-07-27T14:00:00",
  "message": "Hello from producer - message 1",
  "source": "kafka-producer"
}
```

Consumer logs the message and prints it with metadata (topic, partition, offset).


## Tear Down

```bash
docker-compose down -v
```

This will stop all containers and remove generated volumes including SSL artifacts.


## Security Credentials

| Component      | Username | Password    |
|----------------|----------|-------------|
| Kafka Admin    | `admin`  | `admin123`  |
| Kafka Client   | `client` | `client123` |

All credentials are used in the JAAS and environment configurations.

