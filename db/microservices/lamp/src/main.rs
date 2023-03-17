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
    println!("{:?}", sth.payload);
    Ok(())
}
