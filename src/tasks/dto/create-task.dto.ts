import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';

export class CreateTaskDto {
  @ApiProperty({ example: 'Implementar autenticação JWT' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title!: string;

  @ApiPropertyOptional({ example: 'Usar passport + strategy customizada' })
  @IsString()
  @IsOptional()
  description?: string;
}
