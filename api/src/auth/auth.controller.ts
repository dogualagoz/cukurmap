import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { AnonymousAuthDto } from './dto/anonymous-auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('anonymous')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  async anonymous(@Body() dto: AnonymousAuthDto) {
    const { token, user } = await this.authService.anonymous(dto.deviceId);
    return { token, user: { id: user.id, nickname: user.nickname } };
  }
}
