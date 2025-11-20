use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::{accept_async, tungstenite::Message};
use futures_util::{StreamExt, SinkExt};
use tokio::process::Command;
use tracing::{info, debug};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize simple logging
    tracing_subscriber::fmt::init();
    
    let addr = "0.0.0.0:8080";
    let listener = TcpListener::bind(addr).await?;
    info!("WebSocket AT Gateway listening on: {}", addr);

    while let Ok((stream, _)) = listener.accept().await {
        tokio::spawn(handle_connection(stream));
    }

    Ok(())
}

async fn handle_connection(stream: TcpStream) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let ws_stream = accept_async(stream).await?;
    let (mut sender, mut receiver) = ws_stream.split();

    while let Some(msg) = receiver.next().await {
        let msg = msg?;
        
        match msg {
            Message::Text(text) => {
                debug!("Received: {}", text);
                
                // 直接处理纯文本AT命令
                let command = text.trim().to_string();
                
                // Execute AT command
                let command_result = execute_at_command(&command).await;
                let raw = match command_result { Ok(o) => o, Err(e) => e };
                let response_text = parse_and_build(&command, &raw);
                
                sender.send(Message::Text(response_text)).await?;
            }
            Message::Binary(_) => {
                let response_text = r#"{"success":false,"error":"Binary messages not supported","data":null}"#.to_string();
                sender.send(Message::Text(response_text)).await?;
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    Ok(())
}

async fn execute_at_command(command: &str) -> Result<String, String> {
    // Validate AT command
    if !command.trim().starts_with("AT") && !command.trim().starts_with("at") {
        return Err("Command must start with AT".to_string());
    }
    
    // Check for dangerous characters
    if command.contains(';') || command.contains('|') || command.contains('&') || command.contains('`') {
        return Err("Command contains invalid characters".to_string());
    }
    
    // Execute cpetools.sh
    let output = Command::new("cpetools.sh")
        .args(&["-t0", "-c", command])
        .output()
        .await
        .map_err(|e| format!("Failed to execute: {}", e))?;
    
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).trim().to_string())
    }
}

fn escape_json(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\r' => out.push_str("\\r"),
            '\n' => out.push_str("\\n"),
            _ => out.push(ch),
        }
    }
    out
}

fn parse_and_build(command: &str, raw: &str) -> String {
    let binding = raw.replace('\r', "");
    let mut lines: Vec<&str> = binding.split('\n').collect();
    while let Some(last) = lines.last() {
        if last.is_empty() { lines.pop(); } else { break; }
    }
    let cmd_norm = command.trim().to_uppercase();
    if let Some(first) = lines.first().cloned() {
        let first_norm = first.trim().to_uppercase();
        if first_norm == cmd_norm { lines.remove(0); }
    }
    let mut has_ok = false;
    let mut errs: Vec<String> = Vec::new();
    for &l in &lines {
        if l.contains("+CME ERROR") || l.contains("ERROR") { errs.push(l.to_string()); }
        if l.contains("OK") { has_ok = true; }
    }
    if !errs.is_empty() {
        let err_join = errs.join("\r\n");
        let err_json = escape_json(&err_join);
        return format!("{{\"success\":false,\"data\":null,\"error\":\"{}\"}}", err_json);
    }
    let data_join = lines.join("\r\n");
    let data_json = escape_json(&data_join);
    if has_ok || !data_json.is_empty() {
        return format!("{{\"success\":true,\"data\":\"{}\",\"error\":null}}", data_json);
    }
    "{\"success\":true,\"data\":\"\",\"error\":null}".to_string()
}