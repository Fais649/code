#include <epaper_display.h>
#include <lvgl/lvgl.h>
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/task.h"

static const char *TAG = "EPD";

// Define your ePaper display pins
#define BUTTON_1    21
#define BATT_PIN    14

// SD card pins (unused in this context)
#define SD_MISO     16
#define SD_MOSI     15
#define SD_SCLK     11
#define SD_CS       42

// Touch controller pins (unused in this context)
#define TOUCH_SCL   17
#define TOUCH_SDA   18
#define TOUCH_INT   47

// ePaper display SPI pins
#define EPD_MISO    45  // Master In Slave Out (unused for write-only displays)
#define EPD_MOSI    10  // Master Out Slave In
#define EPD_SCLK    48  // Clock
#define EPD_CS      39  // Chip Select

// ePaper control pins (you need to assign these based on your hardware)
#define EPD_DC      13  // Data/Command control pin
#define EPD_RST     12  // Reset pin
#define EPD_BUSY    2   // Busy pin (indicates if the display is processing data)

// SPI host used for the ePaper display
#define SPI_HOST    SPI2_HOST

static spi_device_handle_t spi;

// Function prototypes
static void epd_reset(void);
static void epd_send_command(uint8_t command);
static void epd_send_data(uint8_t data);
static void epd_wait_until_idle(void);
static void epd_init_display(void);

// Initialize the SPI and ePaper display
void epd_init(void) {
    esp_err_t ret;

    ESP_LOGI(TAG, "Initializing ePaper display...");

    // Configure GPIOs for control pins
    gpio_config_t io_conf = {
        .pin_bit_mask = ((1ULL << EPD_DC) | (1ULL << EPD_RST)),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_ENABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_conf);

    gpio_set_direction(EPD_BUSY, GPIO_MODE_INPUT);
    gpio_pullup_en(EPD_BUSY);

    // Initialize SPI bus
    spi_bus_config_t buscfg = {
        .miso_io_num = -1,       // Not used; set to -1
        .mosi_io_num = EPD_MOSI,
        .sclk_io_num = EPD_SCLK,
        .quadwp_io_num = -1,     // Not used
        .quadhd_io_num = -1,     // Not used
        .max_transfer_sz = LV_HOR_RES * LV_VER_RES / 8 + 100,
    };

    ret = spi_bus_initialize(SPI_HOST, &buscfg, SPI_DMA_CH_AUTO);
    ESP_ERROR_CHECK(ret);

    // Configure the ePaper display as an SPI device
    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = 4 * 1000 * 1000,  // 4 MHz
        .mode = 0,                           // SPI mode 0
        .spics_io_num = EPD_CS,              // CS pin
        .queue_size = 7,                     // Queue size
        .pre_cb = NULL,
        .post_cb = NULL,
    };

    ret = spi_bus_add_device(SPI_HOST, &devcfg, &spi);
    ESP_ERROR_CHECK(ret);

    // Initialize the ePaper display
    epd_reset();
    epd_init_display();

    ESP_LOGI(TAG, "ePaper display initialized.");
}

// Reset the ePaper display
static void epd_reset(void) {
    ESP_LOGI(TAG, "Resetting ePaper display...");
    gpio_set_level(EPD_RST, 0);
    vTaskDelay(pdMS_TO_TICKS(200));
    gpio_set_level(EPD_RST, 1);
    vTaskDelay(pdMS_TO_TICKS(200));
}

// Wait until the display is ready
static void epd_wait_until_idle(void) {
    ESP_LOGI(TAG, "Waiting for ePaper display to be idle...");
    while (gpio_get_level(EPD_BUSY) == 1) {  // Busy is high when the display is processing
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    ESP_LOGI(TAG, "ePaper display is now idle.");
}

// Send a command to the ePaper display
static void epd_send_command(uint8_t command) {
    gpio_set_level(EPD_DC, 0);  // Command mode
    spi_transaction_t t = {
        .length = 8,            // Command is 8 bits
        .tx_buffer = &command,
    };
    esp_err_t ret = spi_device_transmit(spi, &t);
    ESP_ERROR_CHECK(ret);
}

// Send data to the ePaper display
static void epd_send_data(uint8_t data) {
    gpio_set_level(EPD_DC, 1);  // Data mode
    spi_transaction_t t = {
        .length = 8,            // Data is 8 bits
        .tx_buffer = &data,
    };
    esp_err_t ret = spi_device_transmit(spi, &t);
    ESP_ERROR_CHECK(ret);
}

// Initialize the ePaper display with the necessary command sequence
static void epd_init_display(void) {
    epd_wait_until_idle();

    // Example initialization sequence (adjust according to your display's datasheet)
    epd_send_command(0x01); // POWER SETTING
    epd_send_data(0x03);
    epd_send_data(0x00);
    epd_send_data(0x2B);
    epd_send_data(0x2B);
    epd_send_data(0x09);

    epd_send_command(0x06); // BOOSTER SOFT START
    epd_send_data(0x17);
    epd_send_data(0x17);
    epd_send_data(0x17);

    epd_send_command(0x04); // POWER ON
    epd_wait_until_idle();

    epd_send_command(0x00); // PANEL SETTING
    epd_send_data(0x3F);

    epd_send_command(0x30); // PLL CONTROL
    epd_send_data(0x3C);

    epd_send_command(0x61); // RESOLUTION SETTING
    epd_send_data(0x03);    // 960 pixels
    epd_send_data(0xC0);
    epd_send_data(0x02);    // 540 pixels
    epd_send_data(0x1C);

    epd_send_command(0x82); // VCOM Voltage
    epd_send_data(0x12);

    epd_send_command(0x50); // VCOM AND DATA INTERVAL SETTING
    epd_send_data(0x97);

    // Additional commands as per your ePaper display's datasheet
}

// Flush function required by LVGL
void epd_flush(lv_disp_drv_t *disp_drv, const lv_area_t *area, lv_color_t *color_map) {
    ESP_LOGI(TAG, "Starting display flush...");

    uint32_t width = (area->x2 - area->x1 + 1);
    uint32_t height = (area->y2 - area->y1 + 1);

    // Send the image data to the display
    epd_send_command(0x10); // WRITE RAM
    for (uint32_t y = 0; y < height; y++) {
        for (uint32_t x = 0; x < width / 8; x++) {
            uint8_t data = color_map[y * (width / 8) + x].full;
            epd_send_data(data);
        }
    }

    // Update the display
    epd_send_command(0x12); // DISPLAY REFRESH
    epd_wait_until_idle();

    lv_disp_flush_ready(disp_drv); // Indicate you are ready with the flushing

    ESP_LOGI(TAG, "Display flush completed.");
}

// Function to initialize the display driver and register it with LVGL
void lvgl_driver_init(void) {
    epd_init();

    static lv_disp_draw_buf_t draw_buf;
    static lv_color_t *buf = NULL;

    if (buf == NULL) {
        buf = heap_caps_malloc(LV_HOR_RES * LV_VER_RES / 8, MALLOC_CAP_DMA);
        if (buf == NULL) {
            ESP_LOGE(TAG, "Failed to allocate display buffer");
            return;
        }
    }

    lv_disp_draw_buf_init(&draw_buf, buf, NULL, LV_HOR_RES * LV_VER_RES / 8);

    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);

    disp_drv.flush_cb = epd_flush;
    disp_drv.draw_buf = &draw_buf;
    disp_drv.hor_res = LV_HOR_RES;
    disp_drv.ver_res = LV_VER_RES;

    lv_disp_drv_register(&disp_drv);

    ESP_LOGI(TAG, "LVGL display driver initialized.");
}

