import { Hono } from 'hono';

const app = new Hono();

app.get('/', (c) => c.text('Hello'));
app.get('/json', (c) => c.json({ message: 'Hello JSON' }));

// Cloud Functions エントリポイントとして Express 互換の req/res とFetch APIを変換
export const httpFunction = async (req, res) => {
  // ExpressのreqをFetch APIのRequestに変換
  const url = new URL(`http://${req.headers.host}${req.url}`);
  const headers = new Headers(req.headers);
  for (const [key, value] of Object.entries(req.headers)) {
    headers.append(key, value);
  }

  // Fetch APIのRequestをHonoのfetchに渡してレスポンスを取得
  const honoRequest = new Request(url, {
    method: req.method,
    headers,
    body: req.method !== 'GET' && req.method !== 'HEAD' ? req.body : undefined,
  });
  const honoResponse = await app.fetch(honoRequest);

  // Fetch APIのResponseをExpressのresに変換
  res.status(honoResponse.status);
  honoResponse.headers.forEach((value, key) => res.setHeader(key, value));
  const responseBody = await honoResponse.text();
  res.send(responseBody);
};
