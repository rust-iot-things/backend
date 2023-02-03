use std::collections::HashMap;

use aws_sdk_dynamodb::model::AttributeValue;
use lambda_http::aws_lambda_events::chrono;
pub use lambda_http::aws_lambda_events::{serde::Deserialize, serde_json};

use chrono::prelude::{DateTime, Utc};
use lambda_runtime::{service_fn, Error, LambdaEvent};
use protocol::{
    message_measurement_humidity::MeasurmentHumidityDescirption,
    message_measurement_temperature::MeasurementTemperatureDescirption,
};
use serde_json::Value;
use std::time::SystemTime;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let thing_input = service_fn(thing_input);
    lambda_runtime::run(thing_input).await?;
    Ok(())
}

async fn thing_input(registry: LambdaEvent<Value>) -> Result<(), Error> {
    println!("Hello World!");
    let config = aws_config::load_from_env().await;
    let dynamodb = aws_sdk_dynamodb::Client::new(&config);
    if let Ok(description) = MeasurmentHumidityDescirption::deserialize(registry.payload.clone()) {
        println!("serialized humidity");
        measurement_humidity(description, dynamodb).await?;
    } else if let Ok(description) = MeasurementTemperatureDescirption::deserialize(registry.payload)
    {
        println!("serialized temperature");
        measurement_temperature(description, dynamodb).await?;
    } else {
        println!("could not deserialize");
    }

    Ok(())
}

fn get_timestamp() -> String {
    let dt: DateTime<Utc> = SystemTime::now().into();
    format!("{}", dt.format("%+"))
}

async fn measurement_humidity(
    description: protocol::message_measurement_humidity::MeasurmentHumidityDescirption,
    dynamodb: aws_sdk_dynamodb::Client,
) -> Result<(), Error> {
    println!("measurement_humidity");

    let _x = AttributeValue::M(HashMap::from([
        ("Timestamp".into(), AttributeValue::N(2.to_string())),
        ("Value".into(), AttributeValue::N(20.to_string())),
    ]));

    let result = dynamodb
        .update_item()
        .table_name("Humidities")
        .key(
            "id",
            AttributeValue::S(description.measurement_humidity.id.to_string()),
        )
        .update_expression(
            "set #Measurements = list_append(if_not_exists(#Measurements, :empty_list), :value)",
        )
        .expression_attribute_names("#Measurements", "Measurements")
        .expression_attribute_values(
            ":value",
            AttributeValue::M(HashMap::from([
                (
                    "Timestamp".into(),
                    AttributeValue::S(get_timestamp().into()),
                ),
                (
                    "Value".into(),
                    AttributeValue::N(description.measurement_humidity.humidity.to_string()),
                ),
            ])),
        )
        .expression_attribute_values(":empty_list", AttributeValue::L(vec![]))
        .return_values(aws_sdk_dynamodb::model::ReturnValue::AllNew)
        .send()
        .await;
    match result {
        Ok(_) => {}
        Err(e) => println!("{}", e),
    }
    Ok(())
}

async fn measurement_temperature(
    description: protocol::message_measurement_temperature::MeasurementTemperatureDescirption,
    dynamodb: aws_sdk_dynamodb::Client,
) -> Result<(), Error> {
    println!("measurement_temperature");

    let result = dynamodb
        .update_item()
        .table_name("Temperatures")
        .key(
            "id",
            AttributeValue::S(description.measurement_temperature.id.to_string()),
        )
        .update_expression(
            "set #Measurements = list_append(if_not_exists(#Measurements, :empty_list), :value)",
        )
        .expression_attribute_names("#Measurements", "Measurements")
        .expression_attribute_values(
            ":value",
            AttributeValue::M(HashMap::from([
                (
                    "Timestamp".into(),
                    AttributeValue::S(get_timestamp().into()),
                ),
                (
                    "Value".into(),
                    AttributeValue::N(description.measurement_temperature.temperature.to_string()),
                ),
            ])),
        )
        .expression_attribute_values(":empty_list", AttributeValue::L(vec![]))
        .return_values(aws_sdk_dynamodb::model::ReturnValue::AllNew)
        .send()
        .await;
    match result {
        Ok(_) => {}
        Err(e) => println!("{}", e),
    }
    Ok(())
}
