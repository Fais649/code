#include "core/lv_disp.h"
#include "core/lv_event.h"
#include "extra/themes/default/lv_theme_default.h"
#include "extra/widgets/calendar/lv_calendar.h"
#include "extra/widgets/keyboard/lv_keyboard.h"
#include "font/lv_font.h"
#include "lvgl.h"
#include "misc/lv_area.h"
#include "widgets/lv_label.h"
LV_FONT_DECLARE(gohufont_14)
#include "core/lv_obj.h"
#include "core/lv_obj_style.h"
#include "misc/lv_color.h"
#include "widgets/lv_textarea.h"
#include <esp_spiffs.h>
#include <stdio.h>
#include <time.h>

#define TIMER_PERIOD_MS 5000
const char *build_date = __DATE__;
const char *build_time = __TIME__;

static const lv_font_t *font;

lv_obj_t *textbox;
lv_obj_t *datepicker;
lv_obj_t *keyboard;
lv_obj_t *datepicker_label;
lv_obj_t *calendar;

static void draw_event_cb(lv_event_t *e) {
  lv_obj_draw_part_dsc_t *dsc = lv_event_get_draw_part_dsc(e);
  if (dsc->part == LV_PART_ITEMS) {
    lv_obj_t *obj = lv_event_get_target(e);
    lv_chart_series_t *ser = lv_chart_get_series_next(obj, NULL);
    uint32_t cnt = lv_chart_get_point_count(obj);
    dsc->rect_dsc->bg_opa = (LV_OPA_COVER * dsc->id) / (cnt - 1);

    lv_coord_t *x_array = lv_chart_get_x_array(obj, ser);
    lv_coord_t *y_array = lv_chart_get_y_array(obj, ser);
    uint32_t start_point = lv_chart_get_x_start_point(obj, ser);
    uint32_t p_act = (start_point + dsc->id) % cnt;
    lv_opa_t x_opa = (x_array[p_act] * LV_OPA_50) / 200;
    lv_opa_t y_opa = (y_array[p_act] * LV_OPA_50) / 1000;

    dsc->rect_dsc->bg_color =
        lv_color_mix(lv_palette_main(LV_PALETTE_GREY),
                     lv_palette_main(LV_PALETTE_GREY), x_opa + y_opa);
  }
}

static void add_data(lv_timer_t *timer) {
  lv_obj_t *chart = timer->user_data;
  lv_chart_set_next_value2(chart, lv_chart_get_series_next(chart, NULL),
                           lv_rand(0, 200), lv_rand(0, 1000));
}

static void button_event_handler(lv_event_t *e);
static void textarea_event_handler(lv_event_t *e);
static void keyboard_event_handler(lv_event_t *e);

void load_textbox_content(void) {
  const char *date = lv_label_get_text(datepicker_label);
  char filePath[256]; // Buffer to store the file path
  snprintf(filePath, sizeof(filePath), "/storage/%s.txt", date);
  printf("FILEPATH: %s", filePath);

  FILE *file = fopen(filePath, "r");
  if (file) {
    fseek(file, 0, SEEK_END);
    long filesize = ftell(file);
    rewind(file);

    char *text = (char *)malloc(filesize + 1);
    if (text) {
      fread(text, 1, filesize, file);
      text[filesize] = '\0';

      lv_textarea_set_text(textbox, text);

      free(text);
    }
    fclose(file);
  } else {
    printf("No saved file found. Starting with empty textbox.\n");
    lv_textarea_set_text(textbox, ""); // If no file found, set empty text
  }
}

void autosave_timer_callback(lv_timer_t *timer) {
  const char *text = lv_textarea_get_text(textbox);

  const char *date = lv_label_get_text(datepicker_label);
  char filePath[256]; // Buffer to store the file path
  snprintf(filePath, sizeof(filePath), "/storage/%s.txt", date);
  printf("FILEPATH: %s", filePath);

  FILE *file = fopen(filePath, "w");
  if (file) {
    fprintf(file, "%s", text);
    fclose(file);
    printf("Autosaved textbox content.\n");
  } else {
    printf("Failed to open file for writing.\n");
  }
}

lv_calendar_date_t getTodayDate() {
  time_t now = time(NULL);
  struct tm *current_time = localtime(&now);

  lv_calendar_date_t today;
  today.year = current_time->tm_year + 1900; // tm_year is years since 1900
  today.month = current_time->tm_mon + 1;    // tm_mon is 0-based, so +1
  today.day = current_time->tm_mday;

  return today;
}

static void calendar_event_callback(lv_event_t *e) {
  lv_event_code_t code = lv_event_get_code(e);
  lv_obj_t *calendar = lv_event_get_current_target(e);

  if (code == LV_EVENT_VALUE_CHANGED) {
    lv_calendar_date_t date;
    if (lv_calendar_get_pressed_date(calendar, &date)) {
      LV_LOG_USER("Clicked date: %02d.%02d.%d", date.day, date.month,
                  date.year);
      lv_calendar_set_showed_date(calendar, date.year, date.month);
      char date_str[32];
      snprintf(date_str, sizeof(date_str), "%04d-%02d-%02d", date.year,
               date.month, date.day); // Format the date
      lv_label_set_text(datepicker_label,
                        date_str); // Set the label to the selected date

      lv_calendar_date_t today = getTodayDate();
      static lv_calendar_date_t
          highlighted_days[3]; /*Only its pointer will be saved so should be
                                  static*/
      highlighted_days[0].year = today.year;
      highlighted_days[0].month = today.month;
      highlighted_days[0].day = today.day;

      highlighted_days[1].year = date.year;
      highlighted_days[1].month = date.month;
      highlighted_days[1].day = date.day;

      lv_calendar_set_highlighted_dates(calendar, highlighted_days, 3);
      lv_obj_add_flag(calendar, LV_OBJ_FLAG_HIDDEN);

      load_textbox_content();
    }
  }
}

static void datepicker_event_callback(lv_event_t *e) {
  if (lv_obj_is_visible(calendar)) {
    lv_obj_add_flag(calendar, LV_OBJ_FLAG_HIDDEN); // Hide the calendar
  } else {
    lv_obj_clear_flag(calendar, LV_OBJ_FLAG_HIDDEN); // Show the calendar
  }
}

static void keyboard_event_handler(lv_event_t *e) {
  if (lv_obj_is_visible(keyboard) && e->code == LV_EVENT_CANCEL) {
    lv_obj_add_flag(keyboard, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_height(textbox, LV_VER_RES - lv_obj_get_y2(datepicker));
    lv_obj_clear_state(textbox, LV_STATE_FOCUSED);
  }
}

static void textarea_event_handler(lv_event_t *e) {
  lv_obj_t *textarea = lv_event_get_target(e);

  if (e->code == LV_EVENT_FOCUSED) {
    lv_obj_set_height(textarea, LV_VER_RES - lv_obj_get_height(keyboard) -
                                    lv_obj_get_height(datepicker));
    lv_obj_clear_flag(keyboard, LV_OBJ_FLAG_HIDDEN);
  }
}

void create_ui(lv_disp_t *disp) {
  lv_theme_default_init(disp, lv_color_black(), lv_color_white(), true,
                        &gohufont_14);
  lv_obj_t *screen = lv_disp_get_scr_act(disp);
  lv_obj_t *scr = lv_obj_create(screen);
  lv_obj_set_size(scr, LV_PCT(100), LV_PCT(100)); // Full screen container
  lv_obj_set_layout(scr, LV_LAYOUT_FLEX);         // Set flex layout
  lv_obj_set_flex_flow(scr, LV_FLEX_FLOW_ROW_WRAP);
  lv_obj_set_style_pad_all(scr, 0, LV_PART_MAIN);
  lv_obj_set_style_pad_gap(scr, 0, 0);
  lv_obj_clear_flag(scr, LV_OBJ_FLAG_SCROLLABLE);

  datepicker = lv_btn_create(scr);
  lv_obj_set_size(datepicker, LV_HOR_RES, LV_VER_RES * 0.1);
  lv_obj_set_style_bg_color(datepicker, lv_color_black(), LV_STATE_DEFAULT);
  lv_obj_set_style_text_color(datepicker, lv_color_white(), LV_STATE_DEFAULT);
  lv_obj_align(datepicker, LV_ALIGN_TOP_MID, 0, 0);
  lv_obj_set_style_pad_gap(datepicker, 0, 0);
  lv_obj_add_event_cb(datepicker, datepicker_event_callback, LV_EVENT_CLICKED,
                      NULL);

  datepicker_label = lv_label_create(datepicker);
  lv_obj_align(datepicker_label, LV_ALIGN_CENTER, 0, 0);
  time_t now = time(NULL);
  struct tm *t = localtime(&now);
  char date_str[32];
  strftime(date_str, sizeof(date_str), "%Y-%m-%d", t);
  lv_label_set_text(datepicker_label, date_str);

  textbox = lv_textarea_create(scr);
  lv_obj_set_size(textbox, LV_HOR_RES, LV_VER_RES);
  lv_obj_align(textbox, LV_ALIGN_TOP_MID, 0, lv_obj_get_y2(datepicker));
  lv_obj_set_style_bg_color(textbox, lv_color_black(), LV_STATE_DEFAULT);
  lv_obj_set_style_text_color(textbox, lv_color_white(), LV_STATE_DEFAULT);
  lv_obj_set_style_text_color(textbox, lv_color_white(), LV_PART_CURSOR);
  lv_obj_set_style_bg_color(textbox, lv_color_white(), LV_PART_CURSOR);
  lv_obj_add_event_cb(textbox, textarea_event_handler, LV_EVENT_FOCUSED, NULL);
  /*lv_obj_set_style_pad_all(textbox, 0, 0);*/

  keyboard = lv_keyboard_create(scr);
  lv_obj_set_size(keyboard, LV_HOR_RES, LV_VER_RES * 0.667);
  lv_obj_set_style_bg_color(keyboard, lv_color_black(), LV_PART_MAIN);
  lv_obj_set_style_text_color(keyboard, lv_color_white(), LV_PART_MAIN);
  lv_obj_set_style_bg_color(keyboard, lv_color_black(), LV_PART_ITEMS);
  lv_obj_set_style_text_color(keyboard, lv_color_white(), LV_PART_ITEMS);
  lv_obj_set_style_bg_color(keyboard, lv_color_black(), LV_PART_ANY);
  lv_obj_set_style_text_color(keyboard, lv_color_white(), LV_PART_ANY);
  lv_obj_add_flag(keyboard, LV_OBJ_FLAG_HIDDEN);
  lv_obj_align(keyboard, LV_ALIGN_BOTTOM_MID, 0, lv_obj_get_y2(textbox));
  lv_keyboard_set_textarea(keyboard, textbox);
  lv_obj_add_event_cb(keyboard, keyboard_event_handler, LV_EVENT_CANCEL, NULL);
  lv_timer_create(autosave_timer_callback, TIMER_PERIOD_MS, NULL);

  calendar = lv_calendar_create(lv_scr_act());
  lv_obj_add_event_cb(calendar, calendar_event_callback, LV_EVENT_VALUE_CHANGED,
                      NULL); // Trigger only on date selection
  lv_calendar_date_t today = getTodayDate();
  lv_calendar_set_today_date(calendar, today.year, today.month, today.day);
  lv_calendar_set_showed_date(calendar, today.year, today.month);
  lv_calendar_set_highlighted_dates(calendar, &today, 1);
  lv_obj_set_size(calendar, 400, 400); // Set size of the calendar
  lv_obj_align(calendar, LV_ALIGN_TOP_MID, 0,
               lv_obj_get_y2(datepicker)); // Center on the screen
  lv_obj_set_style_bg_color(calendar, lv_color_black(), LV_STATE_DEFAULT);
  lv_obj_set_style_text_color(calendar, lv_color_white(), LV_STATE_DEFAULT);
  lv_obj_set_style_bg_color(calendar, lv_color_black(), LV_PART_ITEMS);
  lv_obj_set_style_text_color(calendar, lv_color_white(), LV_PART_ITEMS);
  lv_obj_set_style_bg_color(calendar, lv_color_white(), LV_STATE_CHECKED);
  lv_obj_set_style_text_color(calendar, lv_color_black(), LV_STATE_PRESSED);
  lv_obj_add_flag(calendar, LV_OBJ_FLAG_HIDDEN);

  static lv_style_t style_btn_checked;
  lv_style_init(&style_btn_checked);
  lv_style_set_text_font(&style_btn_checked, &gohufont_14);
  lv_style_set_bg_color(&style_btn_checked, lv_color_make(0xaa, 0xaa, 0xaa));
  lv_obj_add_style(keyboard, &style_btn_checked,
                   LV_PART_ITEMS | LV_STATE_PRESSED);
}
