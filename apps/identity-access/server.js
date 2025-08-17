import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
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

// Demo user store
const users = [
  {
    id: 'user-1',
    email: 'tech@example.com',
    passwordHash: bcrypt.hashSync('Password123!', 10),
    role: 'technician'
  }
];

// Login schema
const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

// Health and info endpoints
app.get('/health', (req, res) => {
  res.status(200).send('ok');
});

app.get('/info', (req, res) => {
  res.json({
    service: 'identity-access',
    version: process.env.SERVICE_VERSION || 'dev',
    timestamp: new Date().toISOString()
  });
});

// Login endpoint
app.post('/login', (req, res) => {
  try {
    const { email, password } = LoginSchema.parse(req.body);
    
    const user = users.find(u => u.email === email);
    if (!user || !bcrypt.compareSync(password, user.passwordHash)) {
      req.log.warn({ email }, 'Login failed: invalid credentials');
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'dev-secret',
      { expiresIn: '1h' }
    );
    
    req.log.info({ userId: user.id }, 'User logged in successfully');
    
    res.json({
      token,
      user: { id: user.id, email: user.email, role: user.role }
    });
  } catch (error) {
    req.log.error({ error: error.message }, 'Login failed');
    res.status(400).json({ error: 'Invalid login data', details: error.message });
  }
});

const port = process.env.PORT || 3001;
app.listen(port, () => {
  logger.info(`Identity & Access service running on port ${port}`);
});
