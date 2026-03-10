use crate::models::http::{HttpError, HttpRequest, HttpResponse};
use crate::services::http_service::HttpService;
use std::sync::Arc;
use tauri::State;
use tokio::sync::Mutex;

/// HTTP service state for Tauri
pub struct HttpServiceState {
    service: Arc<Mutex<HttpService>>,
}

impl HttpServiceState {
    pub fn new() -> Result<Self, HttpError> {
        let service = HttpService::new()?;
        Ok(Self {
            service: Arc::new(Mutex::new(service)),
        })
    }
}

impl Default for HttpServiceState {
    fn default() -> Self {
        Self::new().expect("Failed to create HTTP service state")
    }
}

/// Send an HTTP request
///
/// # Arguments
/// * `request` - The HTTP request to send
/// * `state` - The HTTP service state
///
/// # Returns
/// The HTTP response or an error
#[tauri::command]
pub async fn send_http_request(
    request: HttpRequest,
    state: State<'_, HttpServiceState>,
) -> Result<HttpResponse, HttpError> {
    let service = state.service.lock().await;
    service.send_request(request).await
}

/// Send a simple GET request
///
/// # Arguments
/// * `url` - The URL to send the request to
/// * `state` - The HTTP service state
///
/// # Returns
/// The HTTP response or an error
#[tauri::command]
pub async fn http_get(
    url: String,
    state: State<'_, HttpServiceState>,
) -> Result<HttpResponse, HttpError> {
    let service = state.service.lock().await;
    service.get(url).await
}

/// Send a POST request with JSON body
///
/// # Arguments
/// * `url` - The URL to send the request to
/// * `body` - The JSON body as a string
/// * `state` - The HTTP service state
///
/// # Returns
/// The HTTP response or an error
#[tauri::command]
pub async fn http_post(
    url: String,
    body: String,
    state: State<'_, HttpServiceState>,
) -> Result<HttpResponse, HttpError> {
    let service = state.service.lock().await;
    let request = HttpRequest {
        method: crate::models::http::HttpMethod::Post,
        url,
        body_type: crate::models::http::BodyType::Json,
        body: Some(body),
        ..Default::default()
    };
    service.send_request(request).await
}
