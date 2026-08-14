# API Documentation - {{REPOSITORY_NAME}}

## Overview

This document provides comprehensive API documentation for {{REPOSITORY_NAME}}, including all endpoints, request/response formats, and authentication requirements.

## Table of Contents

- [Base URL](#base-url)
- [Authentication](#authentication)
- [Rate Limiting](#rate-limiting)
- [Error Handling](#error-handling)
- [Endpoints](#endpoints)
  - [Health](#health)
  - [Resources](#resources)
- [Webhooks](#webhooks)
- [WebSocket Events](#websocket-events)
- [SDKs and Libraries](#sdks-and-libraries)

## Base URL

```
Production: https://api.{{REPOSITORY_NAME}}.ai-whisperers.com
Staging: https://staging-api.{{REPOSITORY_NAME}}.ai-whisperers.com
Development: http://localhost:3000
```

## Authentication

The API uses Bearer token authentication. Include your API key in the Authorization header:

```http
Authorization: Bearer YOUR_API_KEY
```

### Obtaining an API Key

1. Log in to the dashboard
2. Navigate to Settings > API Keys
3. Generate a new key with appropriate permissions

### Example Request

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://api.{{REPOSITORY_NAME}}.ai-whisperers.com/v1/resource
```

## Rate Limiting

- **Default limit**: 100 requests per minute
- **Authenticated**: 1000 requests per minute
- **Enterprise**: Custom limits

Rate limit headers:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Error Handling

All errors follow a consistent format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "Additional context"
    }
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

## Endpoints

### Health

#### GET /health

Check API health status.

**Request:**
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### Resources

#### GET /v1/resources

List all resources with optional filtering.

**Request:**
```http
GET /v1/resources?page=1&limit=10&status=active
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `limit` | integer | No | Items per page (default: 10, max: 100) |
| `status` | string | No | Filter by status (active, inactive) |
| `search` | string | No | Search term |

**Response:**
```json
{
  "data": [
    {
      "id": "resource_123",
      "name": "Example Resource",
      "status": "active",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "pages": 10
  }
}
```

#### GET /v1/resources/:id

Get a specific resource by ID.

**Request:**
```http
GET /v1/resources/resource_123
```

**Response:**
```json
{
  "id": "resource_123",
  "name": "Example Resource",
  "description": "Detailed description",
  "status": "active",
  "metadata": {
    "key": "value"
  },
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### POST /v1/resources

Create a new resource.

**Request:**
```http
POST /v1/resources
Content-Type: application/json

{
  "name": "New Resource",
  "description": "Resource description",
  "metadata": {
    "key": "value"
  }
}
```

**Response:**
```json
{
  "id": "resource_124",
  "name": "New Resource",
  "description": "Resource description",
  "status": "active",
  "metadata": {
    "key": "value"
  },
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### PUT /v1/resources/:id

Update an existing resource.

**Request:**
```http
PUT /v1/resources/resource_123
Content-Type: application/json

{
  "name": "Updated Name",
  "description": "Updated description"
}
```

**Response:**
```json
{
  "id": "resource_123",
  "name": "Updated Name",
  "description": "Updated description",
  "status": "active",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-02T00:00:00Z"
}
```

#### DELETE /v1/resources/:id

Delete a resource.

**Request:**
```http
DELETE /v1/resources/resource_123
```

**Response:**
```json
{
  "message": "Resource deleted successfully"
}
```

## Webhooks

Configure webhooks to receive real-time notifications about events.

### Webhook Events

| Event | Description |
|-------|-------------|
| `resource.created` | New resource created |
| `resource.updated` | Resource updated |
| `resource.deleted` | Resource deleted |
| `health.degraded` | System health degraded |

### Webhook Payload

```json
{
  "event": "resource.created",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "id": "resource_123",
    "name": "Example Resource"
  }
}
```

### Webhook Security

All webhooks include a signature header for verification:

```http
X-Webhook-Signature: sha256=SIGNATURE
```

Verify the signature using:
```javascript
const crypto = require('crypto');

function verifyWebhook(body, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');
  return `sha256=${hash}` === signature;
}
```

## WebSocket Events

Connect to real-time updates via WebSocket.

### Connection

```javascript
const ws = new WebSocket('wss://api.{{REPOSITORY_NAME}}.ai-whisperers.com/ws');

ws.on('open', () => {
  ws.send(JSON.stringify({
    type: 'auth',
    token: 'YOUR_API_KEY'
  }));
});
```

### Events

| Event | Description |
|-------|-------------|
| `connected` | Successfully connected |
| `resource.update` | Resource updated in real-time |
| `notification` | System notification |

### Message Format

```json
{
  "type": "resource.update",
  "data": {
    "id": "resource_123",
    "changes": ["status"]
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## SDKs and Libraries

Official SDKs are available for:

- **JavaScript/TypeScript**: `npm install @ai-whisperers/{{REPOSITORY_NAME}}-sdk`
- **Python**: `pip install ai-whisperers-{{REPOSITORY_NAME}}`
- **Go**: `go get github.com/ai-whisperers/{{REPOSITORY_NAME}}-go`

### JavaScript Example

```javascript
const SDK = require('@ai-whisperers/{{REPOSITORY_NAME}}-sdk');

const client = new SDK({
  apiKey: 'YOUR_API_KEY'
});

// List resources
const resources = await client.resources.list({
  limit: 10,
  status: 'active'
});

// Create resource
const newResource = await client.resources.create({
  name: 'New Resource',
  description: 'Description'
});
```

### Python Example

```python
from ai_whisperers_{{REPOSITORY_NAME}} import Client

client = Client(api_key='YOUR_API_KEY')

# List resources
resources = client.resources.list(limit=10, status='active')

# Create resource
new_resource = client.resources.create(
    name='New Resource',
    description='Description'
)
```

## Changelog

### Version 1.0.0 (Current)
- Initial API release
- Basic CRUD operations
- Authentication system
- Webhook support

### Upcoming (v1.1.0)
- GraphQL endpoint
- Batch operations
- Advanced filtering

---

*For support, contact: api-support@ai-whisperers.com*
*API Status: [status.ai-whisperers.com](https://status.ai-whisperers.com)*