import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Appointment } from './appointment.entity';

@Injectable()
export class VeterinaryService {
  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepository: Repository<Appointment>,
  ) {}

  async createAppointment(dto: Partial<Appointment>): Promise<Appointment> {
    const appointment = this.appointmentRepository.create(dto);
    return this.appointmentRepository.save(appointment);
  }

  async findByPet(petId: string): Promise<Appointment[]> {
    return this.appointmentRepository.find({
      where: { petId },
      order: { scheduledAt: 'DESC' },
    });
  }

  async findByUser(userId: string): Promise<Appointment[]> {
    return this.appointmentRepository.find({
      where: { pet: { userId } },
      order: { scheduledAt: 'DESC' },
      relations: ['pet'],
    });
  }
}
