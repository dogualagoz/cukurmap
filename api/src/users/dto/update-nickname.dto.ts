import { Transform } from 'class-transformer';
import { IsString, Length, Matches } from 'class-validator';

export class UpdateNicknameDto {
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @Length(3, 40)
  // Harf, rakam, boşluk ve az sayıda güvenli işaret — kontrol karakteri/emoji taşması yok
  @Matches(/^[\p{L}\p{N} .#_-]+$/u)
  nickname!: string;
}
