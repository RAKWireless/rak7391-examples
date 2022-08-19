/* 
** Whitelist based parser
** Only the variables included in the `whitelist` array will be saved to the bucket
*/

// Whitelist table
const whitelist = ['temperature_1', 'relative_humidity_2', 'barometric_pressure_3', 'analog_out_4', 'rssi', 'snr'];

// Filter only unwanted variables.
payload = payload.filter(x => whitelist.includes(x.variable));
