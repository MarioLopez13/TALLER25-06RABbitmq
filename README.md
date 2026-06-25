# Smart Campus Request Router

## Taller Semana 11 – Message Routing y Message Transformation con RabbitMQ y Apache Camel

### Integrantes

* Mauro Salguero
* Mario López
* Amy Cherrez
* Jonathan Granja
* Mateo Pillajo

---

# 1. Descripción del problema de integración

La institución recibe solicitudes estudiantiles desde diferentes canales, como formularios web, aplicaciones móviles y plataformas administrativas. Todas las solicitudes llegan inicialmente a una única cola de RabbitMQ (`campus.requests.in`), pero cada una debe ser enviada al sistema correspondiente según el tipo de solicitud.

Además, los mensajes llegan en un formato externo que no coincide con el formato interno utilizado por la institución. Por esta razón, antes de enrutar cada solicitud, es necesario transformarla a un modelo canónico que permita mantener una estructura uniforme para todos los sistemas.

---

# 2. Diagrama del flujo

```text
campus.requests.in
        │
        ▼
Message Translator
(Transformación al modelo canónico)
        │
        ▼
Content-Based Router
        │
        ├── campus.admissions.queue
        ├── campus.payments.queue
        ├── campus.support.queue
        ├── campus.academic.queue
        └── campus.manual-review.queue
```

---

# 3. Tecnologías utilizadas

* Java 21
* Spring Boot 3.3.5
* Apache Camel 4.8.1
* RabbitMQ
* Docker Desktop
* Maven
* Visual Studio Code

---

# 4. Instrucciones para ejecutar RabbitMQ

Levantar el contenedor:

```bash
docker compose up -d
```

Verificar que se encuentre en ejecución:

```bash
docker ps
```

Abrir RabbitMQ Management:

```
http://localhost:15678
```

Usuario:

```
guest
```

Contraseña:

```
guest
```

> Se utilizaron los puertos **5678** y **15678** para evitar conflictos con otros proyectos desarrollados previamente.

---

# 5. Configuración del exchange, colas y bindings

Ejecutar el siguiente comando:

```bash
bash scripts/setup-rabbitmq.sh
```

Este script crea:

* Exchange `campus.exchange`
* Cola de entrada `campus.requests.in`
* Cola `campus.admissions.queue`
* Cola `campus.payments.queue`
* Cola `campus.support.queue`
* Cola `campus.academic.queue`
* Cola `campus.manual-review.queue`

Además configura automáticamente todos los bindings necesarios.

---

# 6. Ejecución de la aplicación

Compilar el proyecto:

```bash
mvn clean package
```

Ejecutar la aplicación:

```bash
mvn spring-boot:run
```

---

# 7. Publicación de mensajes de prueba

Ejecutar:

```bash
bash scripts/publish-messages.sh
```

Este script publica automáticamente mensajes para los siguientes casos:

* ADMISSION
* PAYMENT
* SUPPORT
* ACADEMIC
* LIBRARY
* INVALID
* SCHOLARSHIP

---

# 8. Reglas de enrutamiento

| Tipo de solicitud | Cola destino               |
| ----------------- | -------------------------- |
| ADMISSION         | campus.admissions.queue    |
| PAYMENT           | campus.payments.queue      |
| SUPPORT           | campus.support.queue       |
| ACADEMIC          | campus.academic.queue      |
| LIBRARY           | campus.manual-review.queue |
| SCHOLARSHIP       | campus.manual-review.queue |
| Mensaje inválido  | campus.manual-review.queue |

---

# 9. Explicación del Message Translator

El patrón **Message Translator** convierte el mensaje recibido desde el formato externo al modelo canónico utilizado por la institución.

Por ejemplo:

```
request_id
```

se transforma en

```
requestId
```

y los datos del estudiante se agrupan dentro del objeto:

```
student
```

Con esto todos los sistemas trabajan utilizando una misma estructura de datos.

---

# 10. Explicación del Content-Based Router

El patrón **Content-Based Router** analiza el campo **type** del mensaje transformado y decide automáticamente a qué cola debe enviarse.

De esta manera el productor solamente publica el mensaje en una única cola y la lógica de decisión queda centralizada en Apache Camel.

---

# 11. Explicación del modelo canónico

El modelo canónico es una representación estándar de los datos utilizada internamente por la solución.

Su objetivo es reducir el acoplamiento entre sistemas, ya que todos intercambian información utilizando el mismo formato independientemente del origen del mensaje.

---

# 12. Evidencias de ejecución

Se incluyen capturas de:

* Contenedor RabbitMQ en ejecución.
* RabbitMQ Management UI.
* Exchange creado.
* Colas creadas.
* Mensaje publicado.
* Mensaje transformado en ADMISSION.
* Mensaje transformado en PAYMENT.
* Mensaje transformado en SUPPORT.
* Mensaje transformado en ACADEMIC.
* Mensaje LIBRARY enviado a revisión manual.
* Mensaje INVALID enviado a revisión manual.
* Logs de Apache Camel.

---

# 13. Problemas encontrados y solución

Durante el desarrollo se presentaron los siguientes inconvenientes:

* Conflicto de puertos con otro proyecto (Capstone). Se solucionó utilizando los puertos **5678** y **15678**.
* Configuración inicial de Git. Se inicializó el repositorio y posteriormente se realizó el envío a GitHub.
* Consumo de mensajes en RabbitMQ. Se ajustó el modo **Automatic Ack** para revisar correctamente los mensajes almacenados.

---

# 14. Reflexión técnica final

La implementación permitió comprender cómo Apache Camel facilita la integración entre sistemas mediante patrones de integración empresarial.

El uso del **Message Translator** permitió transformar todos los mensajes a un formato común, mientras que el **Content-Based Router** automatizó el envío hacia la cola correspondiente según el tipo de solicitud.

Esta arquitectura reduce el acoplamiento entre productores y consumidores, facilita el mantenimiento y permite incorporar nuevos tipos de solicitudes con cambios mínimos en la solución.
