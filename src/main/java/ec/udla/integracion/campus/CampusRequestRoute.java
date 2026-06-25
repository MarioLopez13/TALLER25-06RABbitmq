package ec.udla.integracion.campus;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class CampusRequestRoute extends RouteBuilder {

    private final CanonicalRequestTranslator canonicalRequestTranslator;

    public CampusRequestRoute(CanonicalRequestTranslator canonicalRequestTranslator) {
        this.canonicalRequestTranslator = canonicalRequestTranslator;
    }

    @Override
    public void configure() {
        onException(Exception.class)
                .handled(true)
                .log("Error procesando mensaje. Se enviará a revisión manual: ${exception.message}")
                .setBody(simple("{\"status\":\"ERROR\",\"reason\":\"Mensaje no pudo ser procesado por la ruta Camel\"}"))
                .to("spring-rabbitmq:campus.exchange?routingKey=campus.manual-review.queue&autoDeclare=false");

        from("spring-rabbitmq:campus.exchange"
                + "?queues=campus.requests.in"
                + "&routingKey=campus.requests.in"
                + "&autoDeclare=false")
                .routeId("ventanilla-digital-campus-router")
                .log("Solicitud recibida en la ventanilla digital: ${body}")
                .process(canonicalRequestTranslator)
                .log("Solicitud convertida al formato interno/canónico: ${body}")
                .log("Área detectada para enrutar: ${exchangeProperty.requestType}")
                .choice()
                    .when(exchangeProperty("requestType").isEqualTo("ADMISSION"))
                        .log("Se envía al área de admisiones")
                        .to("spring-rabbitmq:campus.exchange?routingKey=campus.admissions.queue&autoDeclare=false")
                    .when(exchangeProperty("requestType").isEqualTo("PAYMENT"))
                        .log("Se envía al área de pagos")
                        .to("spring-rabbitmq:campus.exchange?routingKey=campus.payments.queue&autoDeclare=false")
                    .when(exchangeProperty("requestType").isEqualTo("SUPPORT"))
                        .log("Se envía al área de soporte")
                        .to("spring-rabbitmq:campus.exchange?routingKey=campus.support.queue&autoDeclare=false")
                    .when(exchangeProperty("requestType").isEqualTo("ACADEMIC"))
                        .log("Se envía al área académica")
                        .to("spring-rabbitmq:campus.exchange?routingKey=campus.academic.queue&autoDeclare=false")
                    .otherwise()
                        .log("Tipo no reconocido o mensaje inválido. Se envía a revisión manual")
                        .to("spring-rabbitmq:campus.exchange?routingKey=campus.manual-review.queue&autoDeclare=false")
                .end();
    }
}
