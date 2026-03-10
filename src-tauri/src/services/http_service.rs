use crate::models::http::{BodyType, HttpClientConfig, HttpError, HttpMethod, HttpRequest, HttpResponse, KeyValue};
use reqwest::{Client, Response};
use std::collections::HashMap;
use std::time::{Duration, Instant};

/// HTTP service for making requests
pub struct HttpService {
    client: Client,
    config: HttpClientConfig,
}

impl HttpService {
    /// Create a new HTTP service with default configuration
    pub fn new() -> Result<Self, HttpError> {
        let config = HttpClientConfig::default();
        Self::with_config(config)
    }

    /// Create a new HTTP service with custom configuration
    pub fn with_config(config: HttpClientConfig) -> Result<Self, HttpError> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.default_timeout))
            .redirect(if config.follow_redirects {
                reqwest::redirect::Policy::default()
            } else {
                reqwest::redirect::Policy::none()
            })
            .danger_accept_invalid_certs(!config.verify_ssl)
            .build()
            .map_err(|e| HttpError::RequestFailed(e.to_string()))?;

        Ok(Self { client, config })
    }

    /// Send an HTTP request
    pub async fn send_request(&self, request: HttpRequest) -> Result<HttpResponse, HttpError> {
        // Validate URL
        let url = self.build_url(&request)?;

        // Build request
        let mut req_builder = self
            .client
            .request(request.method.to_reqwest(), &url);

        // Add default headers
        for (key, value) in &self.config.default_headers {
            req_builder = req_builder.header(key, value);
        }

        // Add request headers
        for header in &request.headers {
            if header.enabled && !header.key.is_empty() {
                req_builder = req_builder.header(&header.key, &header.value);
            }
        }

        // Add body if present
        req_builder = self.add_body(req_builder, &request)?;

        // Send request and measure time
        let start = Instant::now();
        let response = req_builder
            .send()
            .await
            .map_err(HttpError::from)?;
        let elapsed = start.elapsed().as_millis() as u64;

        // Convert response
        self.convert_response(response, request.id, elapsed).await
    }

    /// Build final URL with query parameters
    fn build_url(&self, request: &HttpRequest) -> Result<String, HttpError> {
        let base_url = &request.url;
        
        // Validate URL
        if base_url.is_empty() {
            return Err(HttpError::InvalidUrl("URL is empty".to_string()));
        }

        // Parse URL
        let mut url = if base_url.starts_with("http://") || base_url.starts_with("https://") {
            base_url.clone()
        } else {
            format!("http://{}", base_url)
        };

        // Add query parameters
        let enabled_params: Vec<&KeyValue> = request
            .params
            .iter()
            .filter(|p| p.enabled && !p.key.is_empty())
            .collect();

        if !enabled_params.is_empty() {
            let query: Vec<String> = enabled_params
                .iter()
                .map(|p| format!("{}={}", urlencoding::encode(&p.key), urlencoding::encode(&p.value)))
                .collect();
            url = format!("{}?{}", url, query.join("&"));
        }

        Ok(url)
    }

    /// Add body to request builder
    fn add_body(
        &self,
        builder: reqwest::RequestBuilder,
        request: &HttpRequest,
    ) -> Result<reqwest::RequestBuilder, HttpError> {
        match request.body_type {
            BodyType::None => Ok(builder),
            BodyType::Json => {
                if let Some(body) = &request.body {
                    // Validate JSON
                    serde_json::from_str::<serde_json::Value>(body)
                        .map_err(|e| HttpError::BodyParseError(e.to_string()))?;
                    Ok(builder.header("Content-Type", "application/json").body(body.clone()))
                } else {
                    Ok(builder)
                }
            }
            BodyType::Text => {
                if let Some(body) = &request.body {
                    Ok(builder.header("Content-Type", "text/plain").body(body.clone()))
                } else {
                    Ok(builder)
                }
            }
            BodyType::Form => {
                if let Some(body) = &request.body {
                    // Parse key=value pairs
                    let form_data: HashMap<String, String> = body
                        .lines()
                        .filter_map(|line| {
                            let parts: Vec<&str> = line.splitn(2, '=').collect();
                            if parts.len() == 2 {
                                Some((parts[0].to_string(), parts[1].to_string()))
                            } else {
                                None
                            }
                        })
                        .collect();
                    Ok(builder
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .form(&form_data))
                } else {
                    Ok(builder)
                }
            }
            BodyType::FormData => {
                // For multipart/form-data, we'd need more complex handling
                // For now, just pass the body as-is
                if let Some(body) = &request.body {
                    Ok(builder
                        .header("Content-Type", "multipart/form-data")
                        .body(body.clone()))
                } else {
                    Ok(builder)
                }
            }
        }
    }

    /// Convert reqwest response to our HttpResponse
    async fn convert_response(
        &self,
        response: Response,
        request_id: Option<String>,
        elapsed_ms: u64,
    ) -> Result<HttpResponse, HttpError> {
        let status = response.status().as_u16();
        let status_text = response.status().canonical_reason().unwrap_or("Unknown").to_string();

        // Extract headers
        let mut headers = HashMap::new();
        for (key, value) in response.headers() {
            if let Ok(value_str) = value.to_str() {
                headers.insert(key.to_string(), value_str.to_string());
            }
        }

        // Get content type
        let content_type = headers
            .get("content-type")
            .cloned()
            .or_else(|| headers.get("Content-Type").cloned());

        // Get body
        let body_bytes = response
            .bytes()
            .await
            .map_err(|e| HttpError::RequestFailed(e.to_string()))?;
        let size = body_bytes.len() as u64;
        let body = String::from_utf8_lossy(&body_bytes).to_string();

        Ok(HttpResponse {
            request_id,
            status,
            status_text,
            headers,
            body,
            size,
            time: elapsed_ms,
            content_type,
        })
    }

    /// Send a simple GET request
    pub async fn get(&self, url: impl Into<String>) -> Result<HttpResponse, HttpError> {
        let request = HttpRequest {
            method: HttpMethod::Get,
            url: url.into(),
            ..Default::default()
        };
        self.send_request(request).await
    }

    /// Send a simple POST request with JSON body
    pub async fn post(
        &self,
        url: impl Into<String>,
        body: impl Serialize,
    ) -> Result<HttpResponse, HttpError> {
        let body_json = serde_json::to_string(&body)
            .map_err(|e| HttpError::BodyParseError(e.to_string()))?;
        
        let request = HttpRequest {
            method: HttpMethod::Post,
            url: url.into(),
            body_type: BodyType::Json,
            body: Some(body_json),
            ..Default::default()
        };
        self.send_request(request).await
    }
}

use serde::Serialize;

impl Default for HttpService {
    fn default() -> Self {
        Self::new().expect("Failed to create default HTTP service")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_http_service_creation() {
        let service = HttpService::new();
        assert!(service.is_ok());
    }

    #[test]
    fn test_build_url_with_params() {
        let service = HttpService::new().unwrap();
        let request = HttpRequest {
            url: "http://example.com/api".to_string(),
            params: vec![
                KeyValue::new("key1", "value1"),
                KeyValue::new("key2", "value with spaces"),
            ],
            ..Default::default()
        };
        
        let url = service.build_url(&request).unwrap();
        assert!(url.contains("key1=value1"));
        assert!(url.contains("key2=value%20with%20spaces"));
    }

    #[test]
    fn test_empty_url_validation() {
        let service = HttpService::new().unwrap();
        let request = HttpRequest {
            url: "".to_string(),
            ..Default::default()
        };
        
        let result = service.build_url(&request);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), HttpError::InvalidUrl(_)));
    }

    #[tokio::test]
    async fn test_simple_get_request() {
        let service = HttpService::new().unwrap();
        // This will fail without network, but tests the flow
        let result = service.get("http://httpbin.org/get").await;
        // We expect this to either succeed or fail with network error
        match result {
            Ok(_) | Err(HttpError::NetworkError(_)) => {}
            Err(e) => panic!("Unexpected error: {:?}", e),
        }
    }
}
