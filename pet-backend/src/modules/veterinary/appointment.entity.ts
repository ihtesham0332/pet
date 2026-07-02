import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Pet } from '../pets/pet.entity';

@Entity('appointments')
export class Appointment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Pet)
  @JoinColumn({ name: 'petId' })
  pet: Pet;

  @Column()
  petId: string;

  @Column()
  vetName: string;

  @Column({ nullable: true })
  vetClinic: string;

  @Column({ type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ default: 'pending' })
  status: string;

  @Column({ default: 'telehealth' })
  type: string;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;
}
