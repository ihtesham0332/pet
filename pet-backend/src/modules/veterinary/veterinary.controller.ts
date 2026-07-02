import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsDateString, IsOptional } from 'class-validator';

import { VeterinaryService } from './veterinary.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

export class CreateAppointmentDto {
  @IsString()
  petId: string;

  @IsString()
  vetName: string;

  @IsOptional()
  @IsString()
  vetClinic?: string;

  @IsDateString()
  scheduledAt: string;

  @IsOptional()
  @IsString()
  type?: string;
}

@ApiTags('Veterinary')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('veterinary')
export class VeterinaryController {
  constructor(private readonly veterinaryService: VeterinaryService) {}

  @Post('appointments')
  @ApiOperation({ summary: 'Create a vet appointment' })
  async createAppointment(@Body() dto: CreateAppointmentDto) {
    return this.veterinaryService.createAppointment(dto);
  }

  @Get('appointments/pet/:petId')
  @ApiOperation({ summary: 'Get appointments for a pet' })
  async petAppointments(@Param('petId') petId: string) {
    return this.veterinaryService.findByPet(petId);
  }

  @Get('appointments/my')
  @ApiOperation({ summary: 'Get my appointments' })
  async myAppointments(@CurrentUser() user: any) {
    return this.veterinaryService.findByUser(user.id);
  }
}
