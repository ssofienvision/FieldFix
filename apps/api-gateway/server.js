import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';
import pino from 'pino';
import pinoHttp from 'pino-http';

const app = express();
const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const httpLogger = pinoHttp({ logger });

app.use(httpLogger);
app.use(express.json());

// Correlation ID middleware
app.use((req, res, next) => {
  const correlationId = req.headers['x-request-id'] || `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  req.correlationId = correlationId;
  res.setHeader('x-request-id', correlationId);
  req.log = req.log.child({ correlationId });
  next();
});

// Health and info endpoints
app.get('/health', (req, res) => {
  res.status(200).send('ok');
});

app.get('/info', (req, res) => {
  res.json({
    service: 'api-gateway',
    version: process.env.SERVICE_VERSION || 'dev',
    timestamp: new Date().toISOString()
  });
});

// Route mappings
const workUrl = process.env.WORK_URL || 'http://localhost:3000';
const identityUrl = process.env.IDENTITY_URL || 'http://localhost:3001';

// Work management routes
app.use('/work', createProxyMiddleware({
  target: workUrl,
  changeOrigin: true,
  pathRewrite: { '^/work': '' },
  onProxyReq: (proxyReq, req) => {
    if (req.correlationId) {
      proxyReq.setHeader('x-request-id', req.correlationId);
    }
  },
  logLevel: 'silent'
}));

// Identity & Access routes
app.use('/auth', createProxyMiddleware({
  target: identityUrl,
  changeOrigin: true,
  pathRewrite: { '^/auth': '' },
  onProxyReq: (proxyReq, req) => {
    if (req.correlationId) {
      proxyReq.setHeader('x-request-id', req.correlationId);
    }
  },
  logLevel: 'silent'
}));

const port = process.env.PORT || 8080;
app.listen(port, () => {
  logger.info(`API Gateway running on port ${port}`);
  logger.info(`Routing /work/* to ${workUrl}`);
  logger.info(`Routing /auth/* to ${identityUrl}`);
});
