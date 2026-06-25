#!/bin/bash

RABBITMQ_API="http://localhost:15678/api"
USER="guest"
PASS="guest"
VHOST="%2F"
EXCHANGE="campus.exchange"

echo "Creando exchange del taller..."
curl -u $USER:$PASS -H "content-type:application/json" \
  -X PUT $RABBITMQ_API/exchanges/$VHOST/$EXCHANGE \
  -d '{"type":"direct","durable":true}'

echo ""
echo "Creando colas..."
QUEUES=(
  "campus.requests.in"
  "campus.admissions.queue"
  "campus.payments.queue"
  "campus.support.queue"
  "campus.academic.queue"
  "campus.manual-review.queue"
)

for QUEUE in "${QUEUES[@]}"
do
  curl -u $USER:$PASS -H "content-type:application/json" \
    -X PUT $RABBITMQ_API/queues/$VHOST/$QUEUE \
    -d '{"durable":true}'
  echo ""
  echo "Cola lista: $QUEUE"
done

echo ""
echo "Creando bindings..."
for QUEUE in "${QUEUES[@]}"
do
  curl -u $USER:$PASS -H "content-type:application/json" \
    -X POST $RABBITMQ_API/bindings/$VHOST/e/$EXCHANGE/q/$QUEUE \
    -d "{\"routing_key\":\"$QUEUE\"}"
  echo ""
  echo "Binding listo para routing key: $QUEUE"
done

echo ""
echo "RabbitMQ configurado en http://localhost:15678"
