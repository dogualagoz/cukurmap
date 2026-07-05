import { IsString, Length, Matches } from 'class-validator';

export class AnonymousAuthDto {
  /** İstemcinin ürettiği rastgele UUID — cihaz donanım kimliği DEĞİL */
  @IsString()
  @Length(16, 128)
  @Matches(/^[A-Za-z0-9-]+$/)
  deviceId!: string;
}
