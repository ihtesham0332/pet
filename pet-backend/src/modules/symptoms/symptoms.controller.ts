import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional } from 'class-validator';

import { SymptomsService } from './symptoms.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

export class AnalyzeSymptomsDto {
  @IsString()
  petId: string;

  @IsString()
  text: string;

  @IsOptional()
  @IsString()
  petSpecies?: string;

  @IsOptional()
  petAge?: number;

  @IsOptional()
  @IsString()
  petBreed?: string;

  @IsOptional()
  petWeightKg?: number;
}

@ApiTags('Symptoms')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('symptoms')
export class SymptomsController {
  constructor(private readonly symptomsService: SymptomsService) {}

  @Post('analyze')
  @ApiOperation({ summary: 'Analyze symptoms with AI and save record' })
  async analyze(@Body() dto: AnalyzeSymptomsDto) {
    const aiResult = await this.symptomsService.analyzeWithAI(dto.text, {
      pet_species: dto.petSpecies,
      pet_age: dto.petAge,
      pet_breed: dto.petBreed,
      pet_weight_kg: dto.petWeightKg,
    });

    const record = await this.symptomsService.create({
      petId: dto.petId,
      symptomsText: dto.text,
      aiDiagnosis: aiResult,
      riskLevel: aiResult.risk_level,
      isEmergency: aiResult.is_emergency,
    });

    return { record, diagnosis: aiResult };
  }

  @Get('pet/:petId')
  @ApiOperation({ summary: 'Get symptom history for a pet' })
  async history(@Param('petId') petId: string) {
    return this.symptomsService.findByPet(petId);
  }
}
