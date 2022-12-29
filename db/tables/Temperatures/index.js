const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json"
  };

  try {
    switch (event.routeKey) {
      case "GET /items/{id}":
        body = await dynamo
          .get({
            TableName: "Temperatures",
            Key: {
              id: parseInt(event.pathParameters.id)
            }
          })
          .promise();
        break;
      case "GET /items":
        body = await dynamo.scan({ TableName: "Temperatures" }).promise();
        break;
      default:
        throw new Error(`Unsupported route: "${event.routeKey}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers
  };
};