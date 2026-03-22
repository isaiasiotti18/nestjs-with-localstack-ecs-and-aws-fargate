import { Injectable, NotFoundException } from '@nestjs/common';
import { EntityManager } from '@mikro-orm/postgresql';
import { Task } from './entities/task.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Injectable()
export class TasksService {
  constructor(private readonly em: EntityManager) {}

  async create(dto: CreateTaskDto): Promise<Task> {
    const task = this.em.create(Task, dto);
    await this.em.flush();
    return task;
  }

  async findAll(): Promise<Task[]> {
    return this.em.find(Task, {}, { orderBy: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.em.findOne(Task, { id });
    if (!task) throw new NotFoundException(`Task ${id} not found`);
    return task;
  }

  async update(id: string, dto: UpdateTaskDto): Promise<Task> {
    const task = await this.findOne(id);
    this.em.assign(task, dto);
    await this.em.flush();
    return task;
  }

  async remove(id: string): Promise<void> {
    const task = await this.findOne(id);
    await this.em.removeAndFlush(task);
  }
}
