import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { CurrentUser } from 'src/common/decorators';
import { RoutineService } from './routine.service';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { GetRoutinesQueryDto } from './dto/get-routines-query.dto';

@Controller('routines')
@ApiTags('Routine')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class RoutineController {
  constructor(private readonly routineService: RoutineService) {}

  @Get()
  async findAll(
    @CurrentUser('id') userId: string,
    @Query() query: GetRoutinesQueryDto,
  ) {
    return await this.routineService.findAll(userId, query);
  }

  @Get(':id')
  async findOne(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
    @Query() query: GetRoutinesQueryDto,
  ) {
    return await this.routineService.findOne(userId, id, query);
  }

  @Post()
  @ApiCreatedResponse({
    description: 'The routine has been successfully created.',
  })
  async create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRoutineDto,
  ) {
    return await this.routineService.create(userId, dto);
  }

  @Patch(':id')
  async update(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateRoutineDto,
  ) {
    return await this.routineService.update(userId, id, dto);
  }

  @Delete(':id')
  async remove(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser('id') userId: string,
  ) {
    return await this.routineService.remove(userId, id);
  }
}
