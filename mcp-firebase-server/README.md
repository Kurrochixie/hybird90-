# MCP Firebase Server

Model Context Protocol (MCP) server for Firebase integration that provides tools to interact with Firebase services.

## Features

- **Firestore Operations**: Read, write, and query documents
- **Firebase Auth**: Get user information and list users
- **Firebase Functions**: Get deployment information

## Setup

### Prerequisites

1. Firebase project with required services enabled
2. Google Cloud credentials configured
3. Node.js 18+ installed

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up Google Cloud credentials:
```bash
# Option 1: Use service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"

# Option 2: Use gcloud CLI
gcloud auth application-default login
```

### Usage

#### Running the MCP Server

```bash
npm start
```

#### MCP Client Configuration

Add this server to your MCP client configuration (e.g., Claude Desktop):

```json
{
  "mcpServers": {
    "firebase": {
      "command": "node",
      "args": ["/path/to/mcp-firebase-server/index.js"],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/path/to/your/service-account-key.json"
      }
    }
  }
}
```

## Available Tools

### Firestore Operations

#### `firestore_read_document`
Read a document from Firestore
- `collection`: Collection name
- `documentId`: Document ID

#### `firestore_write_document`
Write a document to Firestore
- `collection`: Collection name
- `documentId`: Document ID
- `data`: Document data (object)

#### `firestore_query_collection`
Query documents in a Firestore collection
- `collection`: Collection name
- `where`: Query conditions array (optional)
- `limit`: Maximum number of documents (optional)

### Firebase Auth Operations

#### `auth_get_user`
Get user information by UID
- `uid`: User UID

#### `auth_list_users`
List Firebase Auth users
- `maxResults`: Maximum number of users (default: 100)
- `pageToken`: Pagination token (optional)

### Firebase Functions Operations

#### `functions_deploy_info`
Get information about deployed Firebase Functions
- `region`: Function region (default: us-central1)

## Security Notes

- Ensure proper IAM permissions for your service account
- Use environment variables for sensitive data
- Regularly rotate service account keys
- Follow principle of least privilege

## Troubleshooting

### Common Issues

1. **Authentication errors**: Check your Google Cloud credentials
2. **Permission denied**: Verify IAM permissions for Firestore and Auth
3. **Module not found**: Ensure all dependencies are installed

### Debug Mode

Run with debug logging:
```bash
DEBUG=* npm start
