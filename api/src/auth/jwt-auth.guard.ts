import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';

export interface AuthenticatedRequest extends Request {
  user: User;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const [scheme, token] = request.headers.authorization?.split(' ') ?? [];
    if (scheme !== 'Bearer' || !token) {
      throw new UnauthorizedException();
    }

    let payload: { sub: string };
    try {
      payload = await this.jwt.verifyAsync<{ sub: string }>(token, {
        algorithms: ['HS256'],
      });
    } catch {
      throw new UnauthorizedException();
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
    if (!user) {
      throw new UnauthorizedException();
    }
    if (user.isBanned) {
      throw new ForbiddenException();
    }

    request.user = user;
    return true;
  }
}
