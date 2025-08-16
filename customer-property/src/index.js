import express from 'express';
import pino from 'pino';
import { startTracing } from './otel.js';

const serviceName = process.env.SERVICE_NAME || "customer-property";
startTracing(serviceName);

const app = express();
const logger = pino();

app.get('/health', (req, res) => res.status(200).send('ok'));
app.get('/info', (req, res) => res.json({ service: serviceName, version: process.env.SERVICE_VERSION || 'dev' }));

const port = process.env.PORT || 3000;
app.listen(port, () => logger.info(`${serviceName} running on :${port}`));
// change
