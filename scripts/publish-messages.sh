#!/bin/bash

RABBITMQ_API="http://localhost:15678/api"
USER="guest"
PASS="guest"
VHOST="%2F"
EXCHANGE="campus.exchange"
ROUTING_KEY="campus.requests.in"

publish_message() {
  local message="$1"
  local escaped_payload
  escaped_payload=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<< "$message")

  curl -u $USER:$PASS -H "content-type:application/json" \
    -X POST $RABBITMQ_API/exchanges/$VHOST/$EXCHANGE/publish \
    -d "{\"properties\":{\"content_type\":\"application/json\"},\"routing_key\":\"$ROUTING_KEY\",\"payload\":$escaped_payload,\"payload_encoding\":\"string\"}"

  echo ""
  echo "Mensaje enviado:"
  echo "$message"
  echo ""
}

echo "Publicando ADMISSION..."
publish_message '{
  "request_id": "REQ-1001",
  "student_name": "Ana Pérez",
  "student_document": "1712345678",
  "request_type": "ADMISSION",
  "channel": "web",
  "created_at": "2026-06-10T10:30:00"
}'

echo "Publicando PAYMENT..."
publish_message '{
  "request_id": "REQ-1002",
  "student_name": "Luis Gómez",
  "student_document": "1722222222",
  "request_type": "PAYMENT",
  "channel": "mobile",
  "created_at": "2026-06-10T11:00:00"
}'

echo "Publicando SUPPORT..."
publish_message '{
  "request_id": "REQ-1003",
  "student_name": "Carla Torres",
  "student_document": "1733333333",
  "request_type": "SUPPORT",
  "channel": "admin-platform",
  "created_at": "2026-06-10T11:30:00"
}'

echo "Publicando ACADEMIC..."
publish_message '{
  "request_id": "REQ-1004",
  "student_name": "Pedro Morales",
  "student_document": "1744444444",
  "request_type": "ACADEMIC",
  "channel": "web",
  "created_at": "2026-06-10T12:00:00"
}'

echo "Publicando tipo no reconocido LIBRARY..."
publish_message '{
  "request_id": "REQ-1005",
  "student_name": "María Sánchez",
  "student_document": "1755555555",
  "request_type": "LIBRARY",
  "channel": "web",
  "created_at": "2026-06-10T12:30:00"
}'

echo "Publicando mensaje inválido..."
publish_message '{
  "request_id": "REQ-1006",
  "student_name": "Diego Ruiz",
  "channel": "web"
}'

echo "Publicando SCHOLARSHIP para probar ampliación futura..."
publish_message '{
  "request_id": "REQ-1007",
  "student_name": "Sofía Andrade",
  "student_document": "1766666666",
  "request_type": "SCHOLARSHIP",
  "channel": "web",
  "created_at": "2026-06-10T13:00:00"
}'
