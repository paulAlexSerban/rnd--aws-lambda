const aws = require("aws-sdk");
const ses = new aws.SES({ region: "eu-central-1" });

exports.handler = async function (event) {
  console.log("EVENT: ", event);

  // Validate input
  const { senderEmail, senderName, message } = JSON.parse(event.body);
  if (!senderEmail || !senderName || !message) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: `Missing required properties: senderEmail, senderName, message`,
      }),
    };
  }

  // Build SES parameters
  const params = {
    Destination: {
      ToAddresses: ["validated.address@email.om"],
    },
    Message: {
      Body: {
        Text: {
          Data: `You just got a message from ${senderName} - ${senderEmail}: ${message}`,
        },
      },
      Subject: { Data: `Message from ${senderName}` },
    },
    Source: "validated.address@email.om", // Replace with a verified email address
  };

  try {
    // Send email using SES
    const result = await ses.sendEmail(params).promise();
    console.log(result);
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Email sent successfully" }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Error sending email" }),
    };
  }
};
