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
      case "GET /things/{id}":
        body = await dynamo
          .get({
            TableName: "Things",
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
        break;
      case "GET /things":
        body = await dynamo.scan({ TableName: "Things" }).promise();
        break;
      case "PUT /things/{id}":
        let requestJSON = JSON.parse(event.body);
        console.log(`requestedJSON: ${event.routeKey}`)
        await dynamo
          .put({
            TableName: "Things",
            Item: {
              id: event.pathParameters.id,
              name: requestJSON.name
            }
          })
          .promise();
        body = `Put thing ${requestJSON.id}`;
        break;
      case "GET /things/{id}/{db}":
        body = await dynamo
          .get({
            TableName: event.pathParameters.db,
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
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