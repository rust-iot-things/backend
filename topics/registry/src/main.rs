use aws_sdk_dynamodb::{model::AttributeValue, output::GetItemOutput};
pub use lambda_http::aws_lambda_events::{serde::Deserialize, serde_json};
use lambda_runtime::{service_fn, Error, LambdaEvent};
use protocol::{message_request_registartion::RequestRegistrationDescirption, message_set_name};
use serde_json::Value;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let func = service_fn(func);
    lambda_runtime::run(func).await?;
    Ok(())
}

async fn func(registry: LambdaEvent<Value>) -> Result<(), Error> {
    let config = aws_config::load_from_env().await;
    if let Ok(it) = RequestRegistrationDescirption::deserialize(registry.payload.clone()) {
        let iotdataplane = aws_sdk_iotdataplane::Client::new(&config);
        let dynamodb = aws_sdk_dynamodb::Client::new(&config);
        request_registration(it, iotdataplane.clone(), dynamodb.clone()).await?;
    } else {
        println!("can't deserialize payload {:?}", registry.payload);
    }

    Ok(())
}

async fn get_name_by_id(
    dynamodb: aws_sdk_dynamodb::Client,
    id: String,
) -> std::result::Result<
    aws_sdk_dynamodb::output::GetItemOutput,
    aws_sdk_dynamodb::types::SdkError<aws_sdk_dynamodb::error::GetItemError>,
> {
    dynamodb
        .get_item()
        .table_name("Things")
        .key("id", AttributeValue::S(id.to_string()))
        .attributes_to_get("name")
        .send()
        .await
}

pub async fn add_thing(client: aws_sdk_dynamodb::Client, id: String) -> Result<(), Error> {
    let thing_name = "new_thing".to_string();

    let id_av = AttributeValue::S(id.to_string());
    let name_av = AttributeValue::S(thing_name);

    let result = client
        .put_item()
        .table_name("Things")
        .item("id", id_av)
        .item("name", name_av)
        .send()
        .await;
    match result {
        Ok(_) => println!("done"),
        Err(err) => println!("{}", err),
    }

    Ok(())
}

async fn request_registration(
    it: protocol::message_request_registartion::RequestRegistrationDescirption,
    iotdataplane: aws_sdk_iotdataplane::Client,
    dynamodb: aws_sdk_dynamodb::Client,
) -> Result<(), Error> {
    println!("> request_registration");
    let id = it.request_requistration.id;
    let thing_name = get_name(dynamodb, id.clone()).await;
    publish_id_name_on_registry(iotdataplane, id, thing_name).await?;
    println!("<>> request_registration");
    Ok(())
}

async fn get_name(dynamodb: aws_sdk_dynamodb::Client, id: String) -> String {
    println!("> get name");
    let query = get_name_by_id(dynamodb.clone(), id.clone()).await;

    match query {
        Ok(item) => match get_name_from_item_output(item) {
            Ok(name) => name,
            Err(_) => {
                match add_thing(dynamodb, id).await {
                    Ok(_) => println!("could add thing to database"),
                    Err(_) => println!("could not add thing to database"),
                }
                "new_thing".to_string()
            }
        },
        Err(_) => {
            match add_thing(dynamodb, id).await {
                Ok(_) => println!("could add thing to database"),
                Err(_) => println!("could not add thing to database"),
            }
            "new_thing".to_string()
        }
    }
}

fn get_name_from_item_output(item: GetItemOutput) -> Result<String, String> {
    println!("get_name_from_item_output");
    match item.item {
        Some(result) => match result.get("name") {
            Some(name) => match name.as_s() {
                Ok(s) => Ok(s.to_string()),
                Err(_) => Err("failed".to_string()),
            },
            None => Err("failed".to_string()),
        },
        None => Err("failed".to_string()),
    }
}

async fn publish_id_name_on_registry(
    iotdataplane: aws_sdk_iotdataplane::Client,
    id: String,
    thing_name: String,
) -> std::result::Result<
    aws_sdk_iotdataplane::output::PublishOutput,
    aws_sdk_dynamodb::types::SdkError<aws_sdk_iotdataplane::error::PublishError>,
> {
    iotdataplane
        .publish()
        .topic("registry")
        .qos(1)
        .payload(aws_smithy_types::Blob::new(message_set_name::create(
            id.to_string(),
            thing_name.to_string(),
        )))
        .send()
        .await
}
