pub use lambda_http::aws_lambda_events::{serde::Deserialize, serde_json};

use aws_lambda_events::{self, apigw::ApiGatewayV2httpRequest};
use lambda_runtime::{service_fn, Error, LambdaEvent};
use protocol::message_lamp_state;
use serde_json::Value;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let lamp = service_fn(lamp);
    lambda_runtime::run(lamp).await?;
    Ok(())
}

async fn lamp(event: LambdaEvent<Value>) -> Result<(), Error> {
    let http_request: ApiGatewayV2httpRequest =
        serde_json::from_str(&event.payload.to_string()).unwrap();
    println!("Hello World from Lamp!");
    let config = aws_config::load_from_env().await;
    let iotdataplane = aws_sdk_iotdataplane::Client::new(&config);
    if let Some(id) = http_request.path_parameters.get_key_value("id") {
        if let Some(state) = http_request.query_string_parameters.first("state") {
            let payload: String;
            if state == "true" {
                payload = message_lamp_state::create(id.1.into(), true);
            } else if state == "false" {
                payload = message_lamp_state::create(id.1.into(), false);
            } else {
                return Ok(());
            }
            iotdataplane
                .publish()
                .topic("thing_input")
                .qos(1)
                .payload(aws_smithy_types::Blob::new(payload))
                .send()
                .await
                .unwrap();
        }
    }
    Ok(())
}
