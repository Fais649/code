#ifndef BACKGROUND_H
#define BACKGROUND_H

#include <epd_driver.h>
#include "layer.h"
#include <Arduino.h>

class Background : public Layer
{
public:
    Background()
    {
        framebuffer =
            (uint8_t *)ps_calloc(sizeof(uint8_t), EPD_WIDTH * EPD_HEIGHT);
        if (!framebuffer)
        {
            Serial.println("alloc memory failed !!!");
            while (1)
                ;
        }
        memset(framebuffer, 0xFF, EPD_WIDTH * EPD_HEIGHT);
    };

    ~Background();
    int getPosZ() override;

    void render(Rect_t rect)
    {
        epd_poweron();
        epd_draw_image(rect, framebuffer, BLACK_ON_WHITE);
        epd_poweroff();
    };

private:
    uint8_t *framebuffer;
};

#endif
