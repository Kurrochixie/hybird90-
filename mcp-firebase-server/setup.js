#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🔥 MCP Firebase Server Setup');
console.log('============================\n');

// Check if service account key exists
const serviceAccountPath = path.join(__dirname, '..', 'service-account-key.json');
if (fs.existsSync(serviceAccountPath)) {
  console.log('✅ Service account key found at:', serviceAccountPath);
} else {
  console.log('❌ Service account key not found!');
  console.log('\nTo set up Firebase service account:');
  console.log('1. Go to Firebase Console: https://console.firebase.google.com');
  console.log('2. Select your project: testing1do');
  console.log('3. Go to Project Settings > Service accounts');
  console.log('4. Click "Generate new private key"');
  console.log('5. Save the JSON file as: service-account-key.json');
  console.log('6. Place it in the project root directory');
  console.log('\nOr use gcloud CLI:');
  console.log('gcloud auth application-default login');
}

// Check MCP server files
const requiredFiles = ['package.json', 'index.js', 'README.md'];
console.log('\n📁 Checking MCP server files:');

requiredFiles.forEach(file => {
  const filePath = path.join(__dirname, file);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} - Missing!`);
  }
});

// Show configuration
console.log('\n⚙️  MCP Client Configuration:');
console.log('Add this to your Claude Desktop configuration:');
console.log('File: %APPDATA%\\Claude\\claude_desktop_config.json');
console.log('');
console.log(JSON.stringify({
  "mcpServers": {
    "firebase": {
      "command": "node",
      "args": [path.join(__dirname, 'index.js')],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": serviceAccountPath
      }
    }
  }
}, null, 2));

// Show available tools
console.log('\n🛠️  Available MCP Tools:');
const tools = [
  'firestore_read_document - Read document from Firestore',
  'firestore_write_document - Write document to Firestore',
  'firestore_query_collection - Query Firestore collection',
  'auth_get_user - Get Firebase Auth user info',
  'auth_list_users - List Firebase Auth users',
  'functions_deploy_info - Get Functions deployment info'
];

tools.forEach(tool => {
  console.log(`  • ${tool}`);
});

console.log('\n🚀 Setup complete! You can now use Firebase MCP tools.');
