import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import type { User } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateNicknameDto } from './dto/update-nickname.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.usersService.profile(user);
  }

  @Patch('me')
  updateNickname(@CurrentUser() user: User, @Body() dto: UpdateNicknameDto) {
    return this.usersService.updateNickname(user, dto.nickname);
  }
}
