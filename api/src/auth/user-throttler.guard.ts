import { Inject, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import {
  InjectThrottlerOptions,
  InjectThrottlerStorage,
  ThrottlerGuard,
  type ThrottlerModuleOptions,
  type ThrottlerStorage,
} from '@nestjs/throttler';

/**
 * Tracks rate limits per authenticated device (JWT sub) instead of per IP.
 * Anonymous auth means many devices share carrier-grade NAT IPs, so IP-based
 * limits would throttle unrelated users together; falls back to IP for
 * requests without a valid token (e.g. POST /auth/anonymous).
 */
@Injectable()
export class UserThrottlerGuard extends ThrottlerGuard {
  constructor(
    @InjectThrottlerOptions() options: ThrottlerModuleOptions,
    @InjectThrottlerStorage() storageService: ThrottlerStorage,
    reflector: Reflector,
    @Inject(JwtService) private readonly jwt: JwtService,
  ) {
    super(options, storageService, reflector);
  }

  protected async getTracker(req: {
    headers: { authorization?: string };
    ip: string;
  }): Promise<string> {
    const [scheme, token] = (req.headers.authorization ?? '').split(' ');
    if (scheme === 'Bearer' && token) {
      try {
        const payload = await this.jwt.verifyAsync<{ sub: string }>(token);
        return `user:${payload.sub}`;
      } catch {
        // fall through to IP-based tracking for invalid/expired tokens
      }
    }
    return req.ip;
  }
}
