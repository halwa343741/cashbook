import https from 'https';
import fs from 'fs';
import path from 'path';

// Auto-load .env from project root if present
const envPath = path.resolve('.env');
if (fs.existsSync(envPath)) {
  const envLines = fs.readFileSync(envPath, 'utf8').split('\n');
  for (const line of envLines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
      const [key, ...rest] = trimmed.split('=');
      process.env[key.trim()] = rest.join('=').trim();
    }
  }
}

const TOKEN = process.env.FIGMA_TOKEN || process.env.FIGMA_PERSONAL_ACCESS_TOKEN || '';

export function fetchFigma(path) {
  return new Promise((resolve, reject) => {
    const url = new URL(path.startsWith('http') ? path : `https://api.figma.com/v1${path}`);
    const req = https.get(url, {
      headers: {
        'X-Figma-Token': TOKEN
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });
    req.on('error', reject);
  });
}

// If run directly: node fetch-figma.js <file_key_or_url>
if (process.argv[2]) {
  let target = process.argv[2];
  // extract file key if URL was passed
  const match = target.match(/file\/([a-zA-Z0-9]+)/) || target.match(/design\/([a-zA-Z0-9]+)/);
  const fileKey = match ? match[1] : target;
  
  console.log(`Fetching Figma file: ${fileKey}...`);
  fetchFigma(`/files/${fileKey}`).then(res => {
    if (res.name) {
      console.log(`Successfully fetched file: "${res.name}" (Last modified: ${res.lastModified})`);
    } else {
      console.log('Result:', JSON.stringify(res, null, 2).slice(0, 500));
    }
  }).catch(err => console.error('Error:', err.message));
}
