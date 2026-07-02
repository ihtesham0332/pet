import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('admin')
export class AdminController {
  @Get('dashboard')
  @ApiOperation({ summary: 'Get admin dashboard metrics' })
  async getDashboard() {
    return {
      totalUsers: 0,
      totalPets: 0,
      totalSymptomsChecked: 0,
      emergencyEvents: 0,
      revenue: 0,
      activeSubscriptions: 0,
    };
  }
}
