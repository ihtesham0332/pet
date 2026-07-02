import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';

import { EmergencyEvent } from './emergency-event.entity';

@Injectable()
export class EmergencyService {
  private readonly aiServiceUrl: string;

  constructor(
    @InjectRepository(EmergencyEvent)
    private readonly emergencyRepository: Repository<EmergencyEvent>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.aiServiceUrl = this.configService.get(
      'AI_SERVICE_URL',
      'http://localhost:8000/v1',
    );
  }

  async checkEmergency(symptoms: string[], petSpecies: string): Promise<any> {
    try {
      const { data } = await firstValueFrom(
        this.httpService.post(
          `${this.aiServiceUrl}/emergency/check`,
          { symptoms, pet_species: petSpecies },
          {
            headers: {
              'X-API-Key': this.configService.get('AI_SERVICE_KEY', 'dev-internal-key'),
            },
          },
        ),
      );
      return data;
    } catch (error) {
      return this.ruleBasedFallback(symptoms);
    }
  }

  private ruleBasedFallback(symptoms: string[]): any {
    const text = symptoms.join(' ').toLowerCase();
    const redFlags = ['seizure', 'poison', 'bleeding', 'unconscious', 'blue gum', 'not breathing'];

    const detected = redFlags.filter((flag) => text.includes(flag));
    return {
      is_emergency: detected.length > 0,
      severity: detected.length > 0 ? 'high' : 'low',
      red_flags_detected: detected,
      immediate_actions: detected.length > 0
        ? ['Seek immediate veterinary care', 'Keep pet calm and warm']
        : ['Monitor symptoms'],
      vet_required: detected.length > 0,
      detection_method: 'rule_fallback',
    };
  }

  async createEvent(dto: Partial<EmergencyEvent>): Promise<EmergencyEvent> {
    const event = this.emergencyRepository.create(dto);
    return this.emergencyRepository.save(event);
  }

  async findByPet(petId: string): Promise<EmergencyEvent[]> {
    return this.emergencyRepository.find({
      where: { petId },
      order: { createdAt: 'DESC' },
    });
  }
}
