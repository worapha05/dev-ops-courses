const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { server } = require('../src/index');

function request(path) {
  return new Promise((resolve, reject) => {
    const { port } = server.address();
    const req = http.request({ hostname: '127.0.0.1', port, path, method: 'GET' }, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({ status: res.statusCode, body: JSON.parse(body) });
      });
    });
    req.on('error', reject);
    req.end();
  });
}

describe('http routes', () => {
  before(async () => {
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  });

  after(async () => {
    await new Promise((resolve, reject) => {
      server.close((err) => (err ? reject(err) : resolve()));
    });
  });

  it('serves /health', async () => {
    const res = await request('/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ok');
  });

  it('serves / with query string', async () => {
    const res = await request('/?name=DevOps');
    assert.equal(res.status, 200);
    assert.equal(res.body.message, 'Hello, DevOps!');
  });

  it('serves /hello', async () => {
    const res = await request('/hello?name=CI');
    assert.equal(res.status, 200);
    assert.equal(res.body.message, 'Hello, CI!');
  });
});
