import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { User } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ReportsService } from '../reports/reports.service';
import { UpdateNicknameDto } from './dto/update-nickname.dto';
import { QueryMyReportsDto } from './dto/query-my-reports.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly reportsService: ReportsService,
  ) {}

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.usersService.profile(user);
  }

  @Get('me/reports')
  myReports(@CurrentUser() user: User, @Query() query: QueryMyReportsDto) {
    return this.reportsService.findMyReports(user.id, query);
  }

  @Patch('me')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  updateNickname(@CurrentUser() user: User, @Body() dto: UpdateNicknameDto) {
    return this.usersService.updateNickname(user, dto.nickname);
  }

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  async deleteAccount(@CurrentUser() user: User): Promise<void> {
    await this.usersService.deleteAccount(user);
  }
}
