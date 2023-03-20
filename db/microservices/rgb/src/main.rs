pub use lambda_http::aws_lambda_events::{serde::Deserialize, serde_json};

use aws_lambda_events::{self, apigw::ApiGatewayV2httpRequest};
use lambda_runtime::{service_fn, Error, LambdaEvent};
use protocol::message_lamp_rgb;
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
    let config = aws_config::load_from_env().await;
    let iotdataplane = aws_sdk_iotdataplane::Client::new(&config);
    if let Some(id) = http_request.path_parameters.get_key_value("id") {
        if let Some(r) = http_request.query_string_parameters.first("r") {
            if let Some(g) = http_request.query_string_parameters.first("g") {
                if let Some(b) = http_request.query_string_parameters.first("b") {
                    let red = r.to_string().parse::<u32>().unwrap();
                    let green = g.to_string().parse::<u32>().unwrap();
                    let blue = b.to_string().parse::<u32>().unwrap();
                    let payload = message_lamp_rgb::create(id.1.into(), red, green, blue);
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
        }
    }
    Ok(())
}
