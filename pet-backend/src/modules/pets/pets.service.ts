import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Pet } from './pet.entity';

@Injectable()
export class PetsService {
  constructor(
    @InjectRepository(Pet)
    private readonly petsRepository: Repository<Pet>,
  ) {}

  async create(dto: Partial<Pet>): Promise<Pet> {
    const pet = this.petsRepository.create(dto);
    return this.petsRepository.save(pet);
  }

  async findByUser(userId: string): Promise<Pet[]> {
    return this.petsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<Pet> {
    const pet = await this.petsRepository.findOne({ where: { id } });
    if (!pet) throw new NotFoundException('Pet not found');
    return pet;
  }

  async update(id: string, dto: Partial<Pet>): Promise<Pet> {
    await this.petsRepository.update(id, dto);
    return this.findById(id);
  }

  async delete(id: string): Promise<void> {
    const result = await this.petsRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException('Pet not found');
  }
}
