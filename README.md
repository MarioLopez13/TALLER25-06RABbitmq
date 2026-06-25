# Taller Semana 11 - Smart Campus Request Router

## Integrantes
- Mario López
- Integrante 2: __________________
- Integrante 3: __________________

## 1. Descripción del problema

La universidad recibe solicitudes por varios canales, pero todas llegan a una sola cola llamada `campus.requests.in`.

Yo entendí este taller como una **ventanilla digital**: el estudiante manda una solicitud, la aplicación la ordena en un formato interno y después la manda al área correcta. Si el mensaje viene mal o el tipo no existe, no se pierde; se manda a revisión manual.

## 2. Tecnologías utilizadas

- Java 17
- Spring Boot 3.3.5
- Apache Camel 4.8.1
- RabbitMQ
- Docker
- Maven

## 3. Puertos usados

Para no afectar el proyecto capstone, este taller usa otros puertos:

| Servicio | Puerto interno | Puerto en mi PC |
|---|---:|---:|
| RabbitMQ mensajes | 5672 | 5678 |
| RabbitMQ Management UI | 15672 | 15678 |

Consola RabbitMQ:

```text
http://localhost:15678
usuario: guest
contraseña: guest
```

## 4. Diagrama del flujo

```text
campus.requests.in
        |
        v
[ Message Translator ]
        |
        v
[ Content-Based Router ]
        |
        |--> campus.admissions.queue
        |--> campus.payments.queue
        |--> campus.support.queue
        |--> campus.academic.queue
        |--> campus.manual-review.queue
```

## 5. Reglas de enrutamiento

| Tipo de solicitud | Cola destino |
|---|---|
| ADMISSION | campus.admissions.queue |
| PAYMENT | campus.payments.queue |
| SUPPORT | campus.support.queue |
| ACADEMIC | campus.academic.queue |
| Otro valor | campus.manual-review.queue |
| Mensaje inválido | campus.manual-review.queue |

## 6. Cómo ejecutar RabbitMQ

Desde la raíz del proyecto:

```bash
docker compose up -d
```

Verificar:

```bash
docker ps
```

## 7. Crear exchange, colas y bindings

En Linux, Mac o Git Bash:

```bash
chmod +x scripts/setup-rabbitmq.sh
./scripts/setup-rabbitmq.sh
```

Esto crea:

- `campus.exchange`
- `campus.requests.in`
- `campus.admissions.queue`
- `campus.payments.queue`
- `campus.support.queue`
- `campus.academic.queue`
- `campus.manual-review.queue`

## 8. Ejecutar la aplicación

```bash
mvn clean package
mvn spring-boot:run
```

Dejar esta terminal abierta para ver los logs de Apache Camel.

## 9. Publicar mensajes de prueba

Abrir otra terminal y ejecutar:

```bash
chmod +x scripts/publish-messages.sh
./scripts/publish-messages.sh
```

Este script manda mensajes de prueba para:

- ADMISSION
- PAYMENT
- SUPPORT
- ACADEMIC
- LIBRARY
- Mensaje inválido
- SCHOLARSHIP

## 10. Message Translator

El Message Translator se implementa en la clase:

```text
CanonicalRequestTranslator.java
```

Su trabajo es transformar el mensaje externo al formato interno de la universidad.

Ejemplo de cambio:

```text
request_id        -> requestId
student_name      -> student.fullName
student_document  -> student.document
request_type      -> type
channel           -> sourceChannel
created_at        -> createdAt
```

Para mí, esto sirve porque no todos los sistemas hablan igual. Entonces usamos un formato canónico para que la aplicación trabaje con un solo modelo interno.

## 11. Content-Based Router

El Content-Based Router se implementa en:

```text
CampusRequestRoute.java
```

La ruta revisa el campo `requestType`, que sale del campo original `request_type`, y decide a qué cola enviar el mensaje.

En mi explicación, esto es como clasificar trámites en una universidad:

- admisiones va a admisiones,
- pagos va a pagos,
- soporte va a soporte,
- académico va al área académica,
- lo raro o incompleto va a revisión manual.

## 12. Modelo canónico

El modelo canónico usado es:

```json
{
  "requestId": "REQ-1001",
  "student": {
    "fullName": "Ana Pérez",
    "document": "1712345678"
  },
  "type": "ADMISSION",
  "sourceChannel": "web",
  "createdAt": "2026-06-10T10:30:00"
}
```

Este modelo reduce acoplamiento porque los sistemas internos no dependen del formato exacto del productor externo.

## 13. Evidencias que se deben pegar aquí

Pegar capturas de:

1. `docker ps` con RabbitMQ ejecutándose.
2. RabbitMQ Management UI en `http://localhost:15678`.
3. Exchange `campus.exchange`.
4. Colas creadas.
5. Mensaje publicado en `campus.requests.in`.
6. Mensaje transformado en `campus.admissions.queue`.
7. Mensaje transformado en `campus.payments.queue`.
8. Mensaje transformado en `campus.support.queue`.
9. Mensaje transformado en `campus.academic.queue`.
10. Mensaje LIBRARY en `campus.manual-review.queue`.
11. Mensaje inválido en `campus.manual-review.queue`.
12. Logs de Apache Camel.

## 14. Problemas encontrados y solución

Un problema posible fue el conflicto de puertos con otros proyectos. Para evitar eso, no usé los puertos normales de RabbitMQ en la PC. Cambié:

- `5672` a `5678`
- `15672` a `15678`

Así este taller puede correr sin afectar el proyecto capstone.

Otro punto fue que el mensaje podía venir incompleto. Para eso validé los campos obligatorios en el traductor. Si falta algo, lo mando a revisión manual.

## 15. Preguntas de reflexión

### 1. ¿Qué problema resuelve Message Translator?

Resuelve el problema de tener mensajes con formatos diferentes. En este taller convierte el JSON externo al formato canónico interno.

### 2. ¿Qué problema resuelve Content-Based Router?

Permite decidir el destino del mensaje según su contenido. Aquí se usa el tipo de solicitud para mandarla a la cola correcta.

### 3. ¿Por qué primero se transforma y luego se enruta?

Porque es más ordenado trabajar con un formato común. Primero dejo el mensaje limpio y estándar, y luego tomo la decisión de a qué cola enviarlo.

### 4. ¿Qué pasaría si cada productor tuviera que conocer todas las colas destino?

Habría más acoplamiento. Cada sistema tendría que saber detalles internos de RabbitMQ y si cambia una cola tocaría modificar varios productores.

### 5. ¿Qué ventaja tiene usar un modelo canónico interno?

La ventaja es que todos los sistemas internos trabajan con la misma estructura, aunque el mensaje original venga de canales diferentes.

### 6. ¿Qué limitaciones tiene esta solución?

La lógica de enrutamiento está fija en el código. Si aparece un nuevo tipo de solicitud, hay que modificar código, crear cola y agregar pruebas.

### 7. ¿Cómo se podría mejorar el manejo de errores?

Se podría agregar una cola de errores técnicos, más logs, validaciones más completas y guardar el motivo exacto del error para revisarlo después.

### 8. ¿Qué cambios serían necesarios para soportar SCHOLARSHIP?

Sería necesario crear `campus.scholarship.queue`, crear su binding, agregar una condición nueva en el router y hacer pruebas con mensajes tipo `SCHOLARSHIP`.

### 9. ¿Qué riesgos tendría poner toda la lógica en el productor?

El productor quedaría muy cargado y acoplado. Además, si cambian las colas o reglas, tocaría cambiar todos los sistemas que producen mensajes.

### 10. ¿Cómo se relaciona con una arquitectura orientada a eventos?

Se relaciona porque los sistemas se comunican mediante mensajes. Un sistema publica una solicitud y otros sistemas la procesan sin depender directamente entre ellos.

## 16. Apagar solución

Detener Spring Boot con:

```text
CTRL + C
```

Apagar RabbitMQ:

```bash
docker compose down
```

Para borrar datos:

```bash
docker compose down -v
```
