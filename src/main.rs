use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::{accept_async, tungstenite::Message};
use futures_util::{StreamExt, SinkExt};
use tokio::process::Command;
use tracing::{info, debug};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize simple logging
    tracing_subscriber::fmt::init();
    
    let addr = "127.0.0.1:8080";
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
                
                // Send response - simple JSON format
                let response_text = match command_result {
                    Ok(output) => format!(r#"{{"success":true,"error":null,"data":"{}"}}"#, 
                                         output.replace('"', "\\\"")),
                    Err(error) => format!(r#"{{"success":false,"error":"{}","data":null}}"#, 
                                       error.replace('"', "\\\"")),
                };
                
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