import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class RecommendationsService {
  private readonly aiServiceUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.aiServiceUrl = this.configService.get('AI_SERVICE_URL', 'http://localhost:8000/v1');
  }

  async getFoodRecommendation(dto: any): Promise<any> {
    try {
      const { data } = await firstValueFrom(
        this.httpService.post(`${this.aiServiceUrl}/recommendations/food`, dto, {
          headers: {
            'X-API-Key': this.configService.get('AI_SERVICE_KEY', 'dev-internal-key'),
          },
        }),
      );
      return data;
    } catch (error) {
      return {
        recommendations: [],
        reasoning: 'AI service unavailable. Please try again later.',
      };
    }
  }
}
