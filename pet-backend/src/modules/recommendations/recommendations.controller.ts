import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional, IsArray, IsNumber } from 'class-validator';

import { RecommendationsService } from './recommendations.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

export class FoodRecommendationDto {
  @IsString()
  petSpecies: string;

  @IsNumber()
  petAge: number;

  @IsOptional()
  @IsString()
  petBreed?: string;

  @IsOptional()
  @IsArray()
  healthConditions?: string[];
}

@ApiTags('Recommendations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('recommendations')
export class RecommendationsController {
  constructor(private readonly recommendationsService: RecommendationsService) {}

  @Post('food')
  @ApiOperation({ summary: 'Get food and nutrition recommendations' })
  async food(@Body() dto: FoodRecommendationDto) {
    return this.recommendationsService.getFoodRecommendation(dto);
  }
}
