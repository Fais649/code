#include "demos/lv_demos.h"
#include "driver/gpio.h"
#include "esp_err.h"
#include "esp_heap_caps.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "lvgl.h"
#include "sdkconfig.h"
#include <stdio.h>

#include "driver/i2c.h"
#include "esp_lcd_touch_gt911.h"

#include "esp_spiffs.h"
#include "esp_vfs_fat.h"

#include "esp_sntp.h"
#include "esp_system.h"
#include "nvs.h"
#include "nvs_flash.h"
#include <time.h>

#define I2C_MASTER_SCL_IO 9 /*!< GPIO number used for I2C master clock */
#define I2C_MASTER_SDA_IO 8 /*!< GPIO number used for I2C master data  */
#define I2C_MASTER_NUM                                                         \
  0 /*!< I2C master i2c port number, the number of i2c peripheral interfaces   \
       available will depend on the chip */
#define I2C_MASTER_FREQ_HZ 400000   /*!< I2C master clock frequency */
#define I2C_MASTER_TX_BUF_DISABLE 0 /*!< I2C master doesn't need buffer */
#define I2C_MASTER_RX_BUF_DISABLE 0 /*!< I2C master doesn't need buffer */
#define I2C_MASTER_TIMEOUT_MS 1000

#define GPIO_INPUT_IO_4 4
#define GPIO_INPUT_PIN_SEL 1ULL << GPIO_INPUT_IO_4

static const char *TAG = "[APP]";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////// Please update the following configuration according to your
/// LCD spec //////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define LCD_PIXEL_CLOCK_HZ (18 * 1000 * 1000)
#define LCD_BK_LIGHT_ON_LEVEL 1
#define LCD_BK_LIGHT_OFF_LEVEL !LCD_BK_LIGHT_ON_LEVEL
#define PIN_NUM_BK_LIGHT -1
#define PIN_NUM_HSYNC 46
#define PIN_NUM_VSYNC 3
#define PIN_NUM_DE 5
#define PIN_NUM_PCLK 7
#define PIN_NUM_DATA0 14  // B3
#define PIN_NUM_DATA1 38  // B4
#define PIN_NUM_DATA2 18  // B5
#define PIN_NUM_DATA3 17  // B6
#define PIN_NUM_DATA4 10  // B7
#define PIN_NUM_DATA5 39  // G2
#define PIN_NUM_DATA6 0   // G3
#define PIN_NUM_DATA7 45  // G4
#define PIN_NUM_DATA8 48  // G5
#define PIN_NUM_DATA9 47  // G6
#define PIN_NUM_DATA10 21 // G7
#define PIN_NUM_DATA11 1  // R3
#define PIN_NUM_DATA12 2  // R4
#define PIN_NUM_DATA13 42 // R5
#define PIN_NUM_DATA14 41 // R6
#define PIN_NUM_DATA15 40 // R7
#define PIN_NUM_DISP_EN -1

// The pixel number in horizontal and vertical
#define LCD_H_RES 800
#define LCD_V_RES 480

#if CONFIG_DOUBLE_FB
#define LCD_NUM_FB 2
#else
#define LCD_NUM_FB 1
#endif // CONFIG_DOUBLE_FB

#define LVGL_TICK_PERIOD_MS 2
#define LVGL_TASK_MAX_DELAY_MS 500
#define LVGL_TASK_MIN_DELAY_MS 1
#define LVGL_TASK_STACK_SIZE (4 * 1024)
#define LVGL_TASK_PRIORITY 2
#define MOUNT_PATH "/storage"

static SemaphoreHandle_t lvgl_mux = NULL;

// we use two semaphores to sync the VSYNC event and the LVGL task, to avoid
// potential tearing effect
#if CONFIG_AVOID_TEAR_EFFECT_WITH_SEM
SemaphoreHandle_t sem_vsync_end;
SemaphoreHandle_t sem_gui_ready;
#endif

extern void create_ui(lv_disp_t *disp);
extern void load_textbox_content(void);

void init_fs(void) {
  static wl_handle_t wl_handle;
  const esp_vfs_fat_mount_config_t mount_config = {
      .max_files = 4, .format_if_mount_failed = true};
  esp_err_t err = esp_vfs_fat_spiflash_mount_rw_wl(MOUNT_PATH, "storage",
                                                   &mount_config, &wl_handle);
  if (err != ESP_OK) {
    ESP_LOGE(TAG, "Failed to mount FATFS (%s)", esp_err_to_name(err));
    return;
  } else {
    ESP_LOGI(TAG, "FATFS mounted successfully at %s", MOUNT_PATH);
  }

  FILE *test_file = fopen("/storage/test.txt", "w");
  if (test_file) {
    fprintf(test_file, "Filesystem test.\n");
    fclose(test_file);
    ESP_LOGI(TAG, "Test file written successfully.");
  } else {
    ESP_LOGE(TAG, "Failed to write test file (%s)", strerror(errno));
  }
}

/*void init_usb_mass_storage(void) {*/
/*    // Initialize TinyUSB stack*/
/*    const tinyusb_config_t tusb_cfg = {};*/
/*    ESP_ERROR_CHECK(tinyusb_driver_install(&tusb_cfg));*/
/**/
/*    // Set up the MSC class*/
/*    const tinyusb_config_msc_t msc_cfg = {*/
/*        .pdrv = FF_VOLUMES - 1,  // Use the last volume*/
/*        .root_dir = "/storage",   // Mount point of the filesystem*/
/*        .lun = 0,                 // Logical Unit Number*/
/*        .readonly = false,*/
/*    };*/
/*    ESP_ERROR_CHECK(tinyusb_msc_storage_init(&msc_cfg));*/
/*}*/
/*bool is_time_initialized(void) {*/
/*  nvs_handle_t nvs_handle;*/
/*  esp_err_t err;*/
/*  uint8_t initialized = 0; // Default to not initialized*/
/**/
/*  err = nvs_open("storage", NVS_READONLY, &nvs_handle);*/
/*  if (err == ESP_OK) {*/
/*    err = nvs_get_u8(nvs_handle, "time_init", &initialized);*/
/*    nvs_close(nvs_handle);*/
/*    if (err == ESP_OK) {*/
/*      return initialized == 1;*/
/*    }*/
/*  }*/
/*  // If NVS not initialized or key not found, return false*/
/*  return false;*/
/*}*/

void set_time_initialized_flag(void) {
  nvs_handle_t nvs_handle;
  esp_err_t err;

  err = nvs_open("storage", NVS_READWRITE, &nvs_handle);
  if (err == ESP_OK) {
    uint8_t initialized = 1;
    err = nvs_set_u8(nvs_handle, "time_init", initialized);
    if (err == ESP_OK) {
      err = nvs_commit(nvs_handle);
    }
    nvs_close(nvs_handle);
  }
  if (err != ESP_OK) {
    ESP_LOGE(TAG, "Failed to set time initialized flag: %s",
             esp_err_to_name(err));
  }
}

void set_time_from_build(void) {
  struct tm tm;
  memset(&tm, 0, sizeof(struct tm));
  strptime(__DATE__ " " __TIME__, "%b %d %Y %H:%M:%S", &tm);
  time_t t = mktime(&tm);

  struct timeval now = {.tv_sec = t};
  settimeofday(&now, NULL);
  ESP_LOGI(TAG, "Time set to build time: %s", ctime(&t));
}

void initialize_time_if_needed(void) {
  ESP_LOGI(TAG, "First boot after flashing. Setting time...");
  set_time_from_build();
  set_time_initialized_flag();
}

static bool on_vsync_event(esp_lcd_panel_handle_t panel,
                           const esp_lcd_rgb_panel_event_data_t *event_data,
                           void *user_data) {
  BaseType_t high_task_awoken = pdFALSE;
#if CONFIG_AVOID_TEAR_EFFECT_WITH_SEM
  if (xSemaphoreTakeFromISR(sem_gui_ready, &high_task_awoken) == pdTRUE) {
    xSemaphoreGiveFromISR(sem_vsync_end, &high_task_awoken);
  }
#endif
  return high_task_awoken == pdTRUE;
}

static void lvgl_flush_cb(lv_disp_drv_t *drv, const lv_area_t *area,
                          lv_color_t *color_map) {
  esp_lcd_panel_handle_t panel_handle = (esp_lcd_panel_handle_t)drv->user_data;
  int offsetx1 = area->x1;
  int offsetx2 = area->x2;
  int offsety1 = area->y1;
  int offsety2 = area->y2;
#if CONFIG_AVOID_TEAR_EFFECT_WITH_SEM
  xSemaphoreGive(sem_gui_ready);
  xSemaphoreTake(sem_vsync_end, portMAX_DELAY);
#endif
  esp_lcd_panel_draw_bitmap(panel_handle, offsetx1, offsety1, offsetx2 + 1,
                            offsety2 + 1, color_map);
  lv_disp_flush_ready(drv);
}

static void increase_lvgl_tick(void *arg) { lv_tick_inc(LVGL_TICK_PERIOD_MS); }

bool lvgl_lock(int timeout_ms) {
  const TickType_t timeout_ticks =
      (timeout_ms == -1) ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
  return xSemaphoreTakeRecursive(lvgl_mux, timeout_ticks) == pdTRUE;
}

void lvgl_unlock(void) { xSemaphoreGiveRecursive(lvgl_mux); }

static void lvgl_port_task(void *arg) {
  ESP_LOGI(TAG, "Starting LVGL task");
  uint32_t task_delay_ms = LVGL_TASK_MAX_DELAY_MS;
  while (1) {
    if (lvgl_lock(-1)) {
      task_delay_ms = lv_timer_handler();
      lvgl_unlock();
    }
    if (task_delay_ms > LVGL_TASK_MAX_DELAY_MS) {
      task_delay_ms = LVGL_TASK_MAX_DELAY_MS;
    } else if (task_delay_ms < LVGL_TASK_MIN_DELAY_MS) {
      task_delay_ms = LVGL_TASK_MIN_DELAY_MS;
    }
    vTaskDelay(pdMS_TO_TICKS(task_delay_ms));
  }
}

/**
 * @brief i2c master initialization
 */
static esp_err_t i2c_master_init(void) {
  int i2c_master_port = I2C_MASTER_NUM;

  i2c_config_t conf = {
      .mode = I2C_MODE_MASTER,
      .sda_io_num = I2C_MASTER_SDA_IO,
      .scl_io_num = I2C_MASTER_SCL_IO,
      .sda_pullup_en = GPIO_PULLUP_ENABLE,
      .scl_pullup_en = GPIO_PULLUP_ENABLE,
      .master.clk_speed = I2C_MASTER_FREQ_HZ,
  };

  i2c_param_config(i2c_master_port, &conf);

  return i2c_driver_install(i2c_master_port, conf.mode,
                            I2C_MASTER_RX_BUF_DISABLE,
                            I2C_MASTER_TX_BUF_DISABLE, 0);
}

void gpio_init(void) {
  gpio_config_t io_conf = {};
  io_conf.intr_type = GPIO_INTR_DISABLE;
  io_conf.pin_bit_mask = GPIO_INPUT_PIN_SEL;
  io_conf.mode = GPIO_MODE_OUTPUT;
  // io_conf.pull_up_en = 1;
  gpio_config(&io_conf);
}

static void lvgl_touch_cb(lv_indev_drv_t *drv, lv_indev_data_t *data) {
  uint16_t touchpad_x[1] = {0};
  uint16_t touchpad_y[1] = {0};
  uint8_t touchpad_cnt = 0;

  esp_lcd_touch_read_data(drv->user_data);

  bool touchpad_pressed = esp_lcd_touch_get_coordinates(
      drv->user_data, touchpad_x, touchpad_y, NULL, &touchpad_cnt, 1);

  if (touchpad_pressed && touchpad_cnt > 0) {
    data->point.x = touchpad_x[0];
    data->point.y = touchpad_y[0];
    data->state = LV_INDEV_STATE_PR;
  } else {
    data->state = LV_INDEV_STATE_REL;
  }
}

void app_main(void) {
  init_fs();

  esp_err_t ret = nvs_flash_init();
  if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
      ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
    ESP_ERROR_CHECK(nvs_flash_erase());
    ret = nvs_flash_init();
  }
  ESP_ERROR_CHECK(ret);

  // Initialize time if needed
  initialize_time_if_needed();
  static lv_disp_draw_buf_t
      disp_buf; // contains internal graphic buffer(s) called draw buffer(s)
  static lv_disp_drv_t disp_drv; // contains callback functions

#if CONFIG_AVOID_TEAR_EFFECT_WITH_SEM
  ESP_LOGI(TAG, "Create semaphores");
  sem_vsync_end = xSemaphoreCreateBinary();
  assert(sem_vsync_end);
  sem_gui_ready = xSemaphoreCreateBinary();
  assert(sem_gui_ready);
#endif

#if PIN_NUM_BK_LIGHT >= 0
  ESP_LOGI(TAG, "Turn off LCD backlight");
  gpio_config_t bk_gpio_config = {.mode = GPIO_MODE_OUTPUT,
                                  .pin_bit_mask = 1ULL << PIN_NUM_BK_LIGHT};
  ESP_ERROR_CHECK(gpio_config(&bk_gpio_config));
#endif

  ESP_LOGI(TAG, "Install RGB LCD panel driver");
  esp_lcd_panel_handle_t panel_handle = NULL;
  esp_lcd_rgb_panel_config_t panel_config = {
      .data_width = 16, // RGB565 in parallel mode, thus 16bit in width
      .psram_trans_align = 64,
      .num_fbs = LCD_NUM_FB,
#if CONFIG_USE_BOUNCE_BUFFER
      .bounce_buffer_size_px = 10 * LCD_H_RES,
#endif
      .clk_src = LCD_CLK_SRC_DEFAULT,
      .disp_gpio_num = PIN_NUM_DISP_EN,
      .pclk_gpio_num = PIN_NUM_PCLK,
      .vsync_gpio_num = PIN_NUM_VSYNC,
      .hsync_gpio_num = PIN_NUM_HSYNC,
      .de_gpio_num = PIN_NUM_DE,
      .data_gpio_nums =
          {
              PIN_NUM_DATA0,
              PIN_NUM_DATA1,
              PIN_NUM_DATA2,
              PIN_NUM_DATA3,
              PIN_NUM_DATA4,
              PIN_NUM_DATA5,
              PIN_NUM_DATA6,
              PIN_NUM_DATA7,
              PIN_NUM_DATA8,
              PIN_NUM_DATA9,
              PIN_NUM_DATA10,
              PIN_NUM_DATA11,
              PIN_NUM_DATA12,
              PIN_NUM_DATA13,
              PIN_NUM_DATA14,
              PIN_NUM_DATA15,
          },
      .timings =
          {
              .pclk_hz = LCD_PIXEL_CLOCK_HZ,
              .h_res = LCD_H_RES,
              .v_res = LCD_V_RES,
              // The following parameters should refer to LCD spec
              .hsync_back_porch = 8,
              .hsync_front_porch = 8,
              .hsync_pulse_width = 4,
              .vsync_back_porch = 16,
              .vsync_front_porch = 16,
              .vsync_pulse_width = 4,
              .flags.pclk_active_neg = true,
          },
      .flags.fb_in_psram = true, // allocate frame buffer in PSRAM
  };
  ESP_ERROR_CHECK(esp_lcd_new_rgb_panel(&panel_config, &panel_handle));

  ESP_LOGI(TAG, "Register event callbacks");
  esp_lcd_rgb_panel_event_callbacks_t cbs = {
      .on_vsync = on_vsync_event,
  };
  ESP_ERROR_CHECK(esp_lcd_rgb_panel_register_event_callbacks(panel_handle, &cbs,
                                                             &disp_drv));

  ESP_LOGI(TAG, "Initialize RGB LCD panel");
  ESP_ERROR_CHECK(esp_lcd_panel_reset(panel_handle));
  ESP_ERROR_CHECK(esp_lcd_panel_init(panel_handle));

#if PIN_NUM_BK_LIGHT >= 0
  ESP_LOGI(TAG, "Turn on LCD backlight");
  gpio_set_level(PIN_NUM_BK_LIGHT, LCD_BK_LIGHT_ON_LEVEL);
#endif

  ESP_ERROR_CHECK(i2c_master_init());
  ESP_LOGI(TAG, "I2C initialized successfully");
  gpio_init();

  uint8_t write_buf = 0x01;
  i2c_master_write_to_device(I2C_MASTER_NUM, 0x24, &write_buf, 1,
                             I2C_MASTER_TIMEOUT_MS / portTICK_PERIOD_MS);

  // Reset the touch screen. It is recommended that you reset the touch screen
  // before using it.
  write_buf = 0x2C;
  i2c_master_write_to_device(I2C_MASTER_NUM, 0x38, &write_buf, 1,
                             I2C_MASTER_TIMEOUT_MS / portTICK_PERIOD_MS);
  esp_rom_delay_us(100 * 1000);

  gpio_set_level(GPIO_INPUT_IO_4, 0);
  esp_rom_delay_us(100 * 1000);

  write_buf = 0x2E;
  i2c_master_write_to_device(I2C_MASTER_NUM, 0x38, &write_buf, 1,
                             I2C_MASTER_TIMEOUT_MS / portTICK_PERIOD_MS);
  esp_rom_delay_us(200 * 1000);

  esp_lcd_touch_handle_t tp = NULL;
  esp_lcd_panel_io_handle_t tp_io_handle = NULL;

  ESP_LOGI(TAG, "Initialize I2C");

  esp_lcd_panel_io_i2c_config_t tp_io_config =
      ESP_LCD_TOUCH_IO_I2C_GT911_CONFIG();

  ESP_LOGI(TAG, "Initialize touch IO (I2C)");
  /* Touch IO handle */
  ESP_ERROR_CHECK(esp_lcd_new_panel_io_i2c(
      (esp_lcd_i2c_bus_handle_t)I2C_MASTER_NUM, &tp_io_config, &tp_io_handle));
  esp_lcd_touch_config_t tp_cfg = {
      .x_max = LCD_V_RES,
      .y_max = LCD_H_RES,
      .rst_gpio_num = -1,
      .int_gpio_num = -1,
      .flags =
          {
              .swap_xy = 0,
              .mirror_x = 0,
              .mirror_y = 0,
          },
  };
  /* Initialize touch */
  ESP_LOGI(TAG, "Initialize touch controller GT911");
  ESP_ERROR_CHECK(esp_lcd_touch_new_i2c_gt911(tp_io_handle, &tp_cfg, &tp));

  ESP_LOGI(TAG, "Initialize LVGL library");
  lv_init();
  void *buf1 = NULL;
  void *buf2 = NULL;
#if CONFIG_DOUBLE_FB
  ESP_LOGI(TAG, "Use frame buffers as LVGL draw buffers");
  ESP_ERROR_CHECK(
      esp_lcd_rgb_panel_get_frame_buffer(panel_handle, 2, &buf1, &buf2));
  lv_disp_draw_buf_init(&disp_buf, buf1, buf2, LCD_H_RES * LCD_V_RES);
#else
  size_t free_psram = heap_caps_get_free_size(MALLOC_CAP_SPIRAM);
  ESP_LOGI(TAG, "Free PSRAM: %zu bytes", free_psram);

  ESP_LOGI(TAG, "Allocate separate LVGL draw buffers from PSRAM");
  buf1 = heap_caps_aligned_alloc(64, LCD_H_RES * 100 * sizeof(lv_color_t),
                                 MALLOC_CAP_SPIRAM);
  assert(buf1);
  // initialize LVGL draw buffers
  lv_disp_draw_buf_init(&disp_buf, buf1, buf2, LCD_H_RES * 100);

  free_psram = heap_caps_get_free_size(MALLOC_CAP_SPIRAM);
  ESP_LOGI(TAG, "Free PSRAM AFTER buf alloc: %zu bytes", free_psram);
#endif

  ESP_LOGI(TAG, "Register display driver to LVGL");
  lv_disp_drv_init(&disp_drv);
  disp_drv.hor_res = LCD_H_RES;
  disp_drv.ver_res = LCD_V_RES;
  disp_drv.flush_cb = lvgl_flush_cb;
  disp_drv.draw_buf = &disp_buf;
  disp_drv.user_data = panel_handle;
#if CONFIG_DOUBLE_FB
  disp_drv.full_refresh = true; // the full_refresh mode can maintain the
                                // synchronization between the two frame buffers
#endif
  lv_disp_t *disp = lv_disp_drv_register(&disp_drv);

  ESP_LOGI(TAG, "Install LVGL tick timer");
  // Tick interface for LVGL (using esp_timer to generate 2ms periodic event)
  const esp_timer_create_args_t lvgl_tick_timer_args = {
      .callback = &increase_lvgl_tick, .name = "lvgl_tick"};

  static lv_indev_drv_t indev_drv; // Input device driver (Touch)
  lv_indev_drv_init(&indev_drv);
  indev_drv.type = LV_INDEV_TYPE_POINTER;
  indev_drv.disp = disp;
  indev_drv.read_cb = lvgl_touch_cb;
  indev_drv.user_data = tp;

  lv_indev_drv_register(&indev_drv);

  esp_timer_handle_t lvgl_tick_timer = NULL;
  ESP_ERROR_CHECK(esp_timer_create(&lvgl_tick_timer_args, &lvgl_tick_timer));
  ESP_ERROR_CHECK(
      esp_timer_start_periodic(lvgl_tick_timer, LVGL_TICK_PERIOD_MS * 1000));

  lvgl_mux = xSemaphoreCreateRecursiveMutex();
  assert(lvgl_mux);
  ESP_LOGI(TAG, "Create LVGL task");
  xTaskCreate(lvgl_port_task, "LVGL", LVGL_TASK_STACK_SIZE, NULL,
              LVGL_TASK_PRIORITY, NULL);

  ESP_LOGI(TAG, "Display LVGL Scatter Chart");
  // Lock the mutex due to the LVGL APIs are not thread-safe
  if (lvgl_lock(-1)) {
    create_ui(disp);
    load_textbox_content();
    lvgl_unlock();
  }
}
