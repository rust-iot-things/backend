pub use lambda_http::aws_lambda_events::{serde::Deserialize, serde_json};

use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde_json::Value;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let lamp = service_fn(lamp);
    lambda_runtime::run(lamp).await?;
    Ok(())
}

async fn lamp(sth: LambdaEvent<Value>) -> Result<(), Error> {
    println!("Hello World from Lamp!");
    let config = aws_config::load_from_env().await;
    let iotdataplane = aws_sdk_iotdataplane::Client::new(&config);
    let res = format!("{:?}", sth);
    iotdataplane
        .publish()
        .topic("lamp")
        .qos(1)
        .payload(aws_smithy_types::Blob::new(res))
        .send()
        .await
        .unwrap();
    println!("{:?}", sth);
    Ok(())
}
