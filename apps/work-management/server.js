import express from 'express';
import pino from 'pino';
import pinoHttp from 'pino-http';
import { z } from 'zod';

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

// In-memory order storage
const orders = [];

// Order schema
const OrderSchema = z.object({
  title: z.string().min(1),
  customerId: z.string().min(1),
  address: z.string().min(1),
  priority: z.enum(['low', 'medium', 'high']).optional().default('medium')
});

// Health and info endpoints
app.get('/health', (req, res) => {
  res.status(200).send('ok');
});

app.get('/info', (req, res) => {
  res.json({
    service: 'work-management',
    version: process.env.SERVICE_VERSION || 'dev',
    timestamp: new Date().toISOString()
  });
});

// Create order endpoint
app.post('/orders', (req, res) => {
  try {
    const orderData = OrderSchema.parse(req.body);
    const order = {
      id: `order-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      ...orderData,
      status: 'pending',
      createdAt: new Date().toISOString(),
      correlationId: req.correlationId
    };
    
    orders.push(order);
    req.log.info({ orderId: order.id }, 'Order created');
    
    res.status(201).json(order);
  } catch (error) {
    req.log.error({ error: error.message }, 'Order creation failed');
    res.status(400).json({ error: 'Invalid order data', details: error.message });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  logger.info(`Work Management service running on port ${port}`);
});
