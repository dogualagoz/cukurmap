import { Module } from '@nestjs/common';
import { ReportsModule } from '../reports/reports.module';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [ReportsModule],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
