import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, IsDateString } from 'class-validator';

import { PetsService } from './pets.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

export class CreatePetDto {
  @IsString()
  name: string;

  @IsString()
  species: string;

  @IsOptional()
  @IsString()
  breed?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsNumber()
  weightKg?: number;
}

@ApiTags('Pets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('pets')
export class PetsController {
  constructor(private readonly petsService: PetsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new pet' })
  async create(@CurrentUser() user: any, @Body() dto: CreatePetDto) {
    return this.petsService.create({ ...dto, userId: user.id });
  }

  @Get()
  @ApiOperation({ summary: 'Get all pets for current user' })
  async findAll(@CurrentUser() user: any) {
    return this.petsService.findByUser(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get pet by ID' })
  async findById(@Param('id') id: string) {
    return this.petsService.findById(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update pet' })
  async update(@Param('id') id: string, @Body() dto: Partial<CreatePetDto>) {
    return this.petsService.update(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete pet' })
  async delete(@Param('id') id: string) {
    await this.petsService.delete(id);
    return { message: 'Pet deleted' };
  }
}
