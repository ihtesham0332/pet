import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';

import { SymptomRecord } from './symptom-record.entity';

@Injectable()
export class SymptomsService {
  private readonly aiServiceUrl: string;

  constructor(
    @InjectRepository(SymptomRecord)
    private readonly symptomsRepository: Repository<SymptomRecord>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.aiServiceUrl = this.configService.get(
      'AI_SERVICE_URL',
      'http://localhost:8000/v1',
    );
  }

  async create(dto: Partial<SymptomRecord>): Promise<SymptomRecord> {
    const record = this.symptomsRepository.create(dto);
    return this.symptomsRepository.save(record);
  }

  async findByPet(petId: string): Promise<SymptomRecord[]> {
    return this.symptomsRepository.find({
      where: { petId },
      order: { createdAt: 'DESC' },
    });
  }

  async analyzeWithAI(symptomText: string, petInfo: any): Promise<any> {
    try {
      const { data } = await firstValueFrom(
        this.httpService.post(`${this.aiServiceUrl}/symptoms/analyze`, {
          text: symptomText,
          ...petInfo,
        }, {
          headers: { 'X-API-Key': this.configService.get('AI_SERVICE_KEY', 'dev-internal-key') },
        }),
      );
      return data;
    } catch (error) {
      console.error('AI Service call failed:', error.message);
      return {
        risk_level: 'unknown',
        possible_conditions: ['Service unavailable'],
        confidence: 0,
        recommendation: 'AI analysis temporarily unavailable. Please consult a veterinarian.',
        is_emergency: false,
      };
    }
  }
}
