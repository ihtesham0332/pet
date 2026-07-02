import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { VeterinaryController } from './veterinary.controller';
import { VeterinaryService } from './veterinary.service';
import { Appointment } from './appointment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment])],
  controllers: [VeterinaryController],
  providers: [VeterinaryService],
})
export class VeterinaryModule {}
