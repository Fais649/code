//Define 485 communication pins 定义485通信引脚
#define RS485_RX_PIN  15
#define RS485_TX_PIN  16

//Redefine serial port name 重定义串口名
#define RS485 Serial1

void setup() {
  //Initialize 485 device 初始化485设备
  RS485.begin(115200, SERIAL_8N1, RS485_RX_PIN, RS485_TX_PIN);
  while (!RS485) {
    delay(10);//Wait for initialization to succeed 等待初始化成功
  }
}

void loop() {
  //Waiting for 485 data, cannot exceed 120 characters 等待485数据，不能超过120个字符
  if (RS485.available()) {
    //Send the received data back 将接收到的数据发送回去
    RS485.write(RS485.read());
  }
}