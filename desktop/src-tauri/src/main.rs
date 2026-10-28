#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    // Minimal Tauri shell entry point. Add the project's Tauri dependency,
    // tauri.conf.json, capabilities, and frontend before building.
    // Do not expose arbitrary shell or filesystem commands to the webview.
    #[cfg(feature = "tauri-runtime")]
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error while running Harmony desktop application");

    #[cfg(not(feature = "tauri-runtime"))]
    eprintln!("Harmony desktop scaffold: configure Tauri runtime to launch the app.");
}
