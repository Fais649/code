#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "lvgl.h"
#include "epaper_display.h" // Include your display driver header
#include "esp_system.h"

void app_main(void) {
    lv_init();
    lvgl_driver_init();

    // Create a label
    lv_obj_t *label = lv_label_create(lv_scr_act());
    lv_label_set_text(label, "Hello, LVGL on ePaper!");
    lv_obj_align(label, LV_ALIGN_CENTER, 0, 0);

    // Handle LVGL tasks
    while (1) {
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// Tick function for LVGL
void lv_tick_task(void *arg) {
    lv_tick_inc(5);
}
