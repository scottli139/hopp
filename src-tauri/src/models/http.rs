use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// HTTP methods supported by Hopp
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum HttpMethod {
    Get,
    Post,
    Put,
    Delete,
    Patch,
    Head,
    Options,
}

impl HttpMethod {
    /// Convert to reqwest Method
    pub fn to_reqwest(&self) -> reqwest::Method {
        match self {
            HttpMethod::Get => reqwest::Method::GET,
            HttpMethod::Post => reqwest::Method::POST,
            HttpMethod::Put => reqwest::Method::PUT,
            HttpMethod::Delete => reqwest::Method::DELETE,
            HttpMethod::Patch => reqwest::Method::PATCH,
            HttpMethod::Head => reqwest::Method::HEAD,
            HttpMethod::Options => reqwest::Method::OPTIONS,
        }
    }
}

impl Default for HttpMethod {
    fn default() -> Self {
        HttpMethod::Get
    }
}

/// HTTP request body types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum BodyType {
    None,
    Json,
    Text,
    Form,
    FormData,
}

impl Default for BodyType {
    fn default() -> Self {
        BodyType::None
    }
}

/// HTTP request definition
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct HttpRequest {
    /// Request ID for tracking
    pub id: Option<String>,
    /// HTTP method
    pub method: HttpMethod,
    /// Request URL
    pub url: String,
    /// Query parameters
    #[serde(default)]
    pub params: Vec<KeyValue>,
    /// Request headers
    #[serde(default)]
    pub headers: Vec<KeyValue>,
    /// Body type
    #[serde(default)]
    pub body_type: BodyType,
    /// Request body content
    #[serde(default)]
    pub body: Option<String>,
    /// Request timeout in seconds (default: 30)
    #[serde(default = "default_timeout")]
    pub timeout: u64,
}

fn default_timeout() -> u64 {
    30
}

/// Key-value pair for headers, params, form data, etc.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct KeyValue {
    pub key: String,
    pub value: String,
    #[serde(default)]
    pub enabled: bool,
}

impl KeyValue {
    pub fn new(key: impl Into<String>, value: impl Into<String>) -> Self {
        Self {
            key: key.into(),
            value: value.into(),
            enabled: true,
        }
    }
}

/// HTTP response definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HttpResponse {
    /// Request ID that generated this response
    pub request_id: Option<String>,
    /// HTTP status code
    pub status: u16,
    /// HTTP status text
    pub status_text: String,
    /// Response headers
    pub headers: HashMap<String, String>,
    /// Response body
    pub body: String,
    /// Response size in bytes
    pub size: u64,
    /// Response time in milliseconds
    pub time: u64,
    /// Content type
    pub content_type: Option<String>,
}

/// HTTP error types
#[derive(Debug, thiserror::Error, Serialize)]
pub enum HttpError {
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    #[error("Request failed: {0}")]
    RequestFailed(String),
    #[error("Timeout after {0} seconds")]
    Timeout(u64),
    #[error("Invalid header value: {0}")]
    InvalidHeader(String),
    #[error("Body parse error: {0}")]
    BodyParseError(String),
    #[error("Network error: {0}")]
    NetworkError(String),
    #[error("Unknown error: {0}")]
    Unknown(String),
}

impl From<reqwest::Error> for HttpError {
    fn from(err: reqwest::Error) -> Self {
        if err.is_timeout() {
            HttpError::Timeout(30)
        } else if err.is_connect() {
            HttpError::NetworkError(err.to_string())
        } else {
            HttpError::RequestFailed(err.to_string())
        }
    }
}

/// HTTP client configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HttpClientConfig {
    /// Default timeout in seconds
    #[serde(default = "default_timeout")]
    pub default_timeout: u64,
    /// Follow redirects
    #[serde(default = "default_true")]
    pub follow_redirects: bool,
    /// Verify SSL certificates
    #[serde(default = "default_true")]
    pub verify_ssl: bool,
    /// Default headers
    #[serde(default)]
    pub default_headers: HashMap<String, String>,
}

impl Default for HttpClientConfig {
    fn default() -> Self {
        Self {
            default_timeout: 30,
            follow_redirects: true,
            verify_ssl: true,
            default_headers: HashMap::new(),
        }
    }
}

fn default_true() -> bool {
    true
}
