import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';

import { SymptomsService } from './symptoms.service';
import { SymptomsController } from './symptoms.controller';
import { SymptomRecord } from './symptom-record.entity';

@Module({
  imports: [TypeOrmModule.forFeature([SymptomRecord]), HttpModule],
  controllers: [SymptomsController],
  providers: [SymptomsService],
  exports: [SymptomsService],
})
export class SymptomsModule {}
