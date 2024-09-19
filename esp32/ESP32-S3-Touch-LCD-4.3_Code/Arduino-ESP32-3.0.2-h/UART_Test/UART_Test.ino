//Redefine serial port name 重定义串口名
#define UART0 Serial

void setup() {
  //Initialize UART device 初始化UART设备
  UART0.begin(115200, SERIAL_8N1);
  while (!UART0) {
    delay(10);//Wait for initialization to succeed 等待初始化成功
  }
}

void loop() {
  //Waiting for UART data, cannot exceed 120 characters 等待UART数据，不能超过120个字符
  if (UART0.available()) {
    //Send the received data back 将接收到的数据发送回去
    UART0.write(UART0.read());
  }
}