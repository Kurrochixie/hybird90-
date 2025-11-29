#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";
import admin from "firebase-admin";

// Initialize Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  console.error("Firebase initialization error:", error);
}

const db = admin.firestore();
const auth = admin.auth();

const server = new Server(
  {
    name: "mcp-firebase-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "firestore_read_document",
        description: "Read a document from Firestore",
        inputSchema: {
          type: "object",
          properties: {
            collection: {
              type: "string",
              description: "Collection name",
            },
            documentId: {
              type: "string",
              description: "Document ID",
            },
          },
          required: ["collection", "documentId"],
        },
      },
      {
        name: "firestore_write_document",
        description: "Write a document to Firestore",
        inputSchema: {
          type: "object",
          properties: {
            collection: {
              type: "string",
              description: "Collection name",
            },
            documentId: {
              type: "string",
              description: "Document ID",
            },
            data: {
              type: "object",
              description: "Document data",
            },
          },
          required: ["collection", "documentId", "data"],
        },
      },
      {
        name: "firestore_query_collection",
        description: "Query documents in a Firestore collection",
        inputSchema: {
          type: "object",
          properties: {
            collection: {
              type: "string",
              description: "Collection name",
            },
            where: {
              type: "array",
              description: "Query conditions [field, operator, value]",
              items: {
                type: "array",
                items: [
                  { type: "string" },
                  { type: "string" },
                  {}
                ]
              }
            },
            limit: {
              type: "number",
              description: "Maximum number of documents to return",
            },
          },
          required: ["collection"],
        },
      },
      {
        name: "auth_get_user",
        description: "Get user information by UID",
        inputSchema: {
          type: "object",
          properties: {
            uid: {
              type: "string",
              description: "User UID",
            },
          },
          required: ["uid"],
        },
      },
      {
        name: "auth_list_users",
        description: "List Firebase Auth users",
        inputSchema: {
          type: "object",
          properties: {
            maxResults: {
              type: "number",
              description: "Maximum number of users to return (max 1000)",
            },
            pageToken: {
              type: "string",
              description: "Next page token for pagination",
            },
          },
        },
      },
      {
        name: "functions_deploy_info",
        description: "Get information about deployed Firebase Functions",
        inputSchema: {
          type: "object",
          properties: {
            region: {
              type: "string",
              description: "Function region (default: us-central1)",
            },
          },
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "firestore_read_document": {
        const { collection, documentId } = args;
        const docRef = db.collection(collection).doc(documentId);
        const doc = await docRef.get();
        
        if (!doc.exists) {
          return {
            content: [
              {
                type: "text",
                text: `Document not found: ${collection}/${documentId}`,
              },
            ],
          };
        }
        
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ id: doc.id, data: doc.data() }, null, 2),
            },
          ],
        };
      }

      case "firestore_write_document": {
        const { collection, documentId, data } = args;
        const docRef = db.collection(collection).doc(documentId);
        await docRef.set(data);
        
        return {
          content: [
            {
              type: "text",
              text: `Document written successfully: ${collection}/${documentId}`,
            },
          ],
        };
      }

      case "firestore_query_collection": {
        const { collection, where, limit } = args;
        let query = db.collection(collection);
        
        if (where && Array.isArray(where)) {
          where.forEach(condition => {
            if (Array.isArray(condition) && condition.length === 3) {
              query = query.where(condition[0], condition[1], condition[2]);
            }
          });
        }
        
        if (limit) {
          query = query.limit(limit);
        }
        
        const snapshot = await query.get();
        const documents = snapshot.docs.map(doc => ({
          id: doc.id,
          data: doc.data()
        }));
        
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(documents, null, 2),
            },
          ],
        };
      }

      case "auth_get_user": {
        const { uid } = args;
        const userRecord = await auth.getUser(uid);
        
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                uid: userRecord.uid,
                email: userRecord.email,
                displayName: userRecord.displayName,
                emailVerified: userRecord.emailVerified,
                disabled: userRecord.disabled,
                metadata: userRecord.metadata,
              }, null, 2),
            },
          ],
        };
      }

      case "auth_list_users": {
        const { maxResults = 100, pageToken } = args;
        const listUsersResult = await auth.listUsers(maxResults, pageToken);
        
        const users = listUsersResult.users.map(user => ({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          emailVerified: user.emailVerified,
          disabled: user.disabled,
        }));
        
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                users,
                pageToken: listUsersResult.pageToken,
              }, null, 2),
            },
          ],
        };
      }

      case "functions_deploy_info": {
        const { region = "us-central1" } = args;
        
        return {
          content: [
            {
              type: "text",
              text: `Firebase Functions deployment info for region: ${region}\n` +
                    `Note: This MCP server doesn't have direct access to Cloud Functions API.\n` +
                    `Use Firebase CLI or Google Cloud Console for detailed function information.`,
            },
          ],
        };
      }

      default:
        throw new McpError(
          ErrorCode.MethodNotFound,
          `Unknown tool: ${name}`
        );
    }
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Tool execution failed: ${error.message}`
    );
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Firebase Server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
