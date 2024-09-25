use serde_json::Value;
use std::{
    fs::{self, create_dir, File},
    io::Write,
    path::PathBuf,
};

use chrono::Duration;
use tauri::Manager;

#[tauri::command]
fn get_today_date() -> String {
    use chrono::prelude::*;
    let today = Local::now();
    today.format("%Y-%m-%d").to_string()
}

#[tauri::command]
fn change_current_date(date: &str, direction: i64) -> String {
    use chrono::prelude::*;
    let fmt = "%Y-%m-%d";
    let today = NaiveDate::parse_from_str(date, fmt);
    let date = today.unwrap() + Duration::days(direction);
    date.format("%Y-%m-%d").to_string()
}

#[tauri::command]
fn save_content(app: tauri::AppHandle, filename: &str, content: &str) -> String {
    let mut path = get_data_dir(app);
    path.push(filename); // Append the filename to the data directory path

    let json: Value = serde_json::from_str(content).unwrap();
    let serialized = serde_json::to_string_pretty(&json).unwrap();
    let mut file = File::create(path).unwrap();
    file.write_all(serialized.as_bytes()).unwrap();
    let response = "SAVED";
    response.to_string()
}

#[tauri::command]
fn load_content(app: tauri::AppHandle, filename: &str) -> String {
    let mut path = get_data_dir(app);
    path.push(filename); // Append the filename to the data directory path

    let clone = path.clone();
    if path.exists() {
        match fs::read_to_string(path) {
            Ok(content) => content,
            Err(e) => {
                eprintln!("Failed to read file '{}': {}", clone.to_str().unwrap(), e);
                String::new()
            }
        }
    } else {
        let default_content = r#"{
    "todo": "",
    "note": ""
}"#;

        match fs::write(path, default_content) {
            Ok(_) => String::new(),
            Err(e) => {
                eprintln!("Failed to create file '{}': {}", clone.to_str().unwrap(), e);
                String::new()
            }
        }
    }
}

#[tauri::command]
fn get_data_dir(app: tauri::AppHandle) -> PathBuf {
    let docs = app.path().document_dir().expect("lol");
    let docs_dir = docs.join("wispr");

    if !docs_dir.is_dir() {
        let _ = create_dir(docs_dir.clone().as_path());
    }

    docs_dir
    //app.path().app_data_dir().expect("help me lol")
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            get_today_date,
            change_current_date,
            save_content,
            load_content
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
