import Fastify, {
  type FastifyInstance,
  type FastifyReply,
  type FastifyRequest,
} from 'fastify';
import cors from '@fastify/cors';
import { AppError } from './errors.js';
import { bearerUser, type AccessClaims } from './jwt.js';

export type AuthedRequest = FastifyRequest & { user: AccessClaims };

export async function createService(opts: {
  name: string;
  port: number;
  bodyLimit?: number;
}): Promise<FastifyInstance> {
  const app = Fastify({
    logger: true,
    bodyLimit: opts.bodyLimit ?? 1_048_576,
  });
  await app.register(cors, { origin: true });

  app.setErrorHandler((error, _req, reply) => {
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({
        error: error.code,
        message: error.message,
      });
    }
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ZodError') {
      return reply.status(400).send({
        error: 'validation_error',
        message: 'Invalid request body',
        details: (error as { issues?: unknown }).issues ?? error,
      });
    }
    app.log.error(error);
    const statusCode =
      typeof error === 'object' &&
      error &&
      'statusCode' in error &&
      typeof (error as { statusCode: unknown }).statusCode === 'number'
        ? (error as { statusCode: number }).statusCode
        : 500;
    return reply.status(statusCode).send({
      error: statusCode === 500 ? 'internal' : 'request_error',
      message:
        statusCode === 500
          ? 'Internal server error'
          : error instanceof Error
            ? error.message
            : 'Request error',
    });
  });

  app.get('/healthz', async () => ({ ok: true, service: opts.name }));

  return app;
}

export function requireAuth(
  req: FastifyRequest,
  _reply?: FastifyReply,
): AccessClaims {
  try {
    const user = bearerUser(req.headers.authorization);
    if (!user) {
      throw new AppError('Unauthorized', 401, 'unauthorized');
    }
    (req as AuthedRequest).user = user;
    return user;
  } catch {
    throw new AppError('Unauthorized', 401, 'unauthorized');
  }
}

export function requireRole(
  user: AccessClaims,
  allowed: string | string[],
): void {
  const needed = Array.isArray(allowed) ? allowed : [allowed];
  const has = needed.some((role) => user.roles.includes(role));
  if (!has) {
    throw new AppError('Forbidden', 403, 'forbidden');
  }
}

export async function listen(app: FastifyInstance, port: number): Promise<void> {
  await app.listen({ port, host: '0.0.0.0' });
}
