import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Pet } from '../pets/pet.entity';

@Entity('symptom_records')
export class SymptomRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Pet)
  @JoinColumn({ name: 'petId' })
  pet: Pet;

  @Column()
  petId: string;

  @Column({ type: 'text' })
  symptomsText: string;

  @Column({ type: 'simple-array', nullable: true })
  imageUrls: string[];

  @Column({ nullable: true })
  voiceUrl: string;

  @Column({ type: 'jsonb', nullable: true })
  aiDiagnosis: object;

  @Column({ nullable: true })
  riskLevel: string;

  @Column({ default: false })
  isEmergency: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
