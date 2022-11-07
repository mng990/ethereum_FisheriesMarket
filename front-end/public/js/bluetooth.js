let THdata;

function connectToBle() {
  // Connect to a device by passing the service UUID
  blueTooth.connect(0xFFE0, gotCharacteristics);
}


// A function that will be called once got characteristics
function gotCharacteristics(error, characteristics) {
  if (error) { 
    console.log('error: ', error);
  }
  console.log('characteristics: ', characteristics);
  blueToothCharacteristic = characteristics[0];

  console.log(blueToothCharacteristic);

  blueTooth.startNotifications(blueToothCharacteristic, gotValue, 'string');
  
  isConnected = blueTooth.isConnected();

  blueTooth.onDisconnected(onDisconnected);
  
}

function gotValue(value) {
  var word = "";
  var now = parseInt(new Date()/1000).toString();

  console.log('value: ', value);
  word += value;

  var result = word.split('+');
  console.log('humi : ',result[0]);
  console.log('temp : ',result[1]);

  word += "+" + now;
  console.log(word);

  resulttt = word;
}

function onDisconnected() {
  console.log('Device got disconnected.');
  isConnected = false;
}

function MeasureData() {
  sendData("AT+START\n");
}

function sendData(command) {
  const inputValue = command;
  if (!("TextEncoder" in window)) {
    console.log("Sorry, this browser does not support TextEncoder...");
  }
  var enc = new TextEncoder(); // always utf-8
  blueToothCharacteristic.writeValue(enc.encode(inputValue));
}

function sleep(ms) {
  const wakeUpTime = Date.now() + ms;
  while (Date.now() < wakeUpTime) {}
}