import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Pet } from '../pets/pet.entity';

@Entity('emergency_events')
export class EmergencyEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Pet)
  @JoinColumn({ name: 'petId' })
  pet: Pet;

  @Column()
  petId: string;

  @Column()
  severity: string;

  @Column({ type: 'simple-array', nullable: true })
  redFlags: string[];

  @Column({ nullable: true })
  actionTaken: string;

  @Column({ default: 'active' })
  status: string;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ nullable: true })
  resolvedAt: Date;
}
