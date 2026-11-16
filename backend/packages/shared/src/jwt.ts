import jwt from 'jsonwebtoken';
import { env, envInt } from './config.js';

export type AccessClaims = {
  sub: string;
  phone: string;
  roles: string[];
};

export function signAccessToken(claims: AccessClaims): string {
  const secret = env('JWT_SECRET', 'maekel-dev-secret-change-me');
  const ttl = envInt('JWT_ACCESS_TTL_SEC', 3600);
  return jwt.sign(
    { phone: claims.phone, roles: claims.roles },
    secret,
    { subject: claims.sub, expiresIn: ttl },
  );
}

export function verifyAccessToken(token: string): AccessClaims {
  const secret = env('JWT_SECRET', 'maekel-dev-secret-change-me');
  const payload = jwt.verify(token, secret) as jwt.JwtPayload;
  if (!payload.sub || typeof payload.phone !== 'string') {
    throw new Error('Invalid token');
  }
  return {
    sub: payload.sub,
    phone: payload.phone,
    roles: Array.isArray(payload.roles) ? (payload.roles as string[]) : [],
  };
}

export function bearerUser(authorizationHeader?: string): AccessClaims | null {
  if (!authorizationHeader?.startsWith('Bearer ')) return null;
  const token = authorizationHeader.slice('Bearer '.length).trim();
  if (!token) return null;
  return verifyAccessToken(token);
}
