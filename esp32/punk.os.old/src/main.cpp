#include "HWCDC.h"
#include "ed047tc1.h"
#include "esp32-hal.h"
#ifndef BOARD_HAS_PSRAM
#error "Please enable PSRAM !!!"
#endif

#include "epd_driver.h"
#include "pins.h"
#include <Arduino.h>

uint8_t *bgBuffer = NULL;
uint8_t *uiBuffer = NULL;
uint8_t *fgBuffer = NULL;

bool first = true;

void drawBg();
void drawUi();
void drawFg();
void allocateBuffers();

void setup()
{
  Serial.begin(115200);
  delay(1000);


  epd_init();

  /*Wire.begin(16, 15, 400000U);*/
  epd_poweron();
  epd_clear();
  epd_poweroff();

  allocateBuffers();
}

void allocateBuffers()
{
  bgBuffer =
      (uint8_t *)ps_calloc(sizeof(uint8_t), EPD_WIDTH * EPD_HEIGHT);
  if (!bgBuffer)
  {
    Serial.println("alloc memory failed !!!");
    while (1)
      ;
  }
  memset(bgBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);

  uiBuffer =
      (uint8_t *)ps_calloc(sizeof(uint8_t), EPD_WIDTH * EPD_HEIGHT);
  if (!uiBuffer)
  {
    Serial.println("alloc memory failed !!!");
    while (1)
      ;
  }
  memset(uiBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);

  fgBuffer =
      (uint8_t *)ps_calloc(sizeof(uint8_t), EPD_WIDTH * EPD_HEIGHT);
  if (!fgBuffer)
  {
    Serial.println("alloc memory failed !!!");
    while (1)
      ;
  }
  memset(fgBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);
}

void drawBg()
{
  epd_poweron();
  epd_draw_rect(0, 0, EPD_WIDTH, EPD_HEIGHT, 0, bgBuffer);
  Rect_t area = {.x = 0, .y = 0, .width = EPD_WIDTH, .height = EPD_HEIGHT};
  epd_draw_grayscale_image(area, bgBuffer);
  epd_poweroff();
}

void drawUi()
{
  epd_poweron();
  epd_draw_rect(100, 100, 100, 100, 0, uiBuffer);
  Rect_t area = {.x = 100, .y = 100, .width = 100, .height = 100};
  epd_draw_grayscale_image(area, uiBuffer);
  epd_poweroff();
}

void drawFg()
{
  epd_fill_rect(100, 100, EPD_WIDTH - 200, EPD_HEIGHT - 200, 200, fgBuffer);
  Rect_t area = {.x = 100, .y = 100, .width = EPD_WIDTH - 200, .height = EPD_HEIGHT - 200};
  epd_draw_image(area, fgBuffer, BLACK_ON_WHITE);
}

void loop()
{
  /*Serial.println("Drawing Bg...");*/
  /*drawBg();*/
  /*delay(1000);*/
  /**/
  /*Serial.println("Drawing Ui...");*/
  /*drawUi();*/
  /*delay(1000);*/
  /**/
  /*Serial.println("Drawing Fg...");*/
  /*// drawFg();*/
  /*delay(3000);*/
  /**/
  /*memset(uiBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);*/
  /*memset(fgBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);*/
  /**/
  /*epd_poweron();*/
  /*epd_clear();*/
  /*epd_poweroff();*/
  /**/
  epd_poweron();

  epd_draw_hline(10, random(10, EPD_HEIGHT), EPD_WIDTH - 20, 0, bgBuffer);
  epd_draw_grayscale_image(epd_full_screen(), bgBuffer);
  delay(1000);

  epd_draw_circle(random(10, EPD_WIDTH), random(10, EPD_HEIGHT), 120, 0, bgBuffer);
  epd_draw_grayscale_image(epd_full_screen(), bgBuffer);
  delay(1000);

  int yPos = random(10, EPD_HEIGHT);
  epd_fill_rect(10, 50, 100, 100, 0, bgBuffer);
  epd_draw_grayscale_image(epd_full_screen(), bgBuffer);
  delay(1000);

  epd_fill_rect(40, 50, 100, 100, 4, bgBuffer);
  Rect_t test = {.x = 40, .y=50, .width = 100, .height = 100};
  epd_draw_grayscale_image(test, bgBuffer);
  delay(1000);

  epd_fill_circle(random(10, EPD_WIDTH), random(10, EPD_HEIGHT), random(10, 160), 0, bgBuffer);
  epd_draw_grayscale_image(epd_full_screen(), bgBuffer);

  delay(1000);
  memset(bgBuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);
  epd_clear();
  epd_poweroff();
}
