#ifndef Drawing
#define Drawing

#include <epd_driver.h>

struct Drawing {
protected:
public:
    struct Circle {
    uint8_t framebuffer;
    Rect_t rect;
        public:
            void setX(int valX) { rect.x = valX; };
            // int getX() { return pos.getX(); };
            // int getY() { return pos.getY(); };
            Rect_t getRect() {};
            void draw() {
                epd_poweron();
                epd_draw_circle(12,12,12,0, &framebuffer);
                epd_draw_image(rect, &framebuffer, WHITE_ON_BLACK);
                epd_poweroff();
            };
    };
    
};

#endif
