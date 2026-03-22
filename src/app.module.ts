import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { HealthModule } from './health/health.module';
import { TasksModule } from './tasks/tasks.module';
import mikroOrmConfig from './config/mikro-orm.config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MikroOrmModule.forRoot(mikroOrmConfig),
    HealthModule,
    TasksModule,
  ],
})
export class AppModule {}
