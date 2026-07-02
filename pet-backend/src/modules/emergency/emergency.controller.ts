import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsArray, IsString } from 'class-validator';

import { EmergencyService } from './emergency.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

export class EmergencyCheckDto {
  @IsArray()
  @IsString({ each: true })
  symptoms: string[];

  @IsString()
  petId: string;

  @IsString()
  petSpecies: string;
}

@ApiTags('Emergency')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  @Post('check')
  @ApiOperation({ summary: 'Check if symptoms require emergency care' })
  async check(@Body() dto: EmergencyCheckDto) {
    const result = await this.emergencyService.checkEmergency(
      dto.symptoms,
      dto.petSpecies,
    );

    if (result.is_emergency) {
      await this.emergencyService.createEvent({
        petId: dto.petId,
        severity: result.severity,
        redFlags: result.red_flags_detected,
        actionTaken: result.immediate_actions?.join('; '),
      });
    }

    return result;
  }
}
