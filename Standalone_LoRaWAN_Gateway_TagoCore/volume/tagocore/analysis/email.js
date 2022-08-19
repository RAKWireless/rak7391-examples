const { Analysis, Device, Services, Utils } = require("@tago-io/sdk");

// The function myAnalysis will run when you execute your analysis
async function myAnalysis(context, scope) {
  
    // reads the values from the environment and saves it in the variable env_vars
    const env_vars = Utils.envToJson(context.environment);

    if (!env_vars.email) {
        return context.log("email environment variable not found");
    }

    // Start the email service
    const email = new Services({ token: context.token }).email;

    // Get the 5 last records in the device bucket.
    const temperatureItem = scope.find((i) => i.variable === 'temperature_1');

    // Send the email.
    const service_response = await email.send({
        message: "Temperature value: " + temperatureItem.value,
        subject: "TagoCore report",
        to: env_vars.email
    });

    context.log(service_response);

}

module.exports = new Analysis(myAnalysis);