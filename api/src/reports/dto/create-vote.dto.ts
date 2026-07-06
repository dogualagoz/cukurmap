import { IsEnum } from 'class-validator';
import { VoteType } from '@prisma/client';

export class CreateVoteDto {
  @IsEnum(VoteType)
  type: VoteType;
}
