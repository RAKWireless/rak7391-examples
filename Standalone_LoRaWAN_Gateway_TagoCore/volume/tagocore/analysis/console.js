const { Analysis } = require("@tago-io/sdk");

// The function myAnalysis will run when you execute your analysis
async function myAnalysis(context, scope) {
   
    //console.log("Context: ", context);
    //console.log("Scope: ", scope);

    const temperatureItem = scope.find((i) => i.variable === 'temperature_1');
    console.log("Temperature is at:", temperatureItem.value);

}

module.exports = new Analysis(myAnalysis);

