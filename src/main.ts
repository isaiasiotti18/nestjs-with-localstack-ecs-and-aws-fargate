import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { ValidationPipe, Logger } from "@nestjs/common";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger("Bootstrap");
  const port = process.env.PORT || 3000;

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.enableCors();

  const swaggerConfig = new DocumentBuilder()
    .setTitle("Bun + NestJS API")
    .setDescription("Boilerplate API running on Bun with MikroORM")
    .setVersion("1.0")
    .addTag("tasks")
    .addTag("health")
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup("api/docs", app, document);

  await app.listen(port);
  logger.log(`Application running on port ${port}`);
  logger.log(`Swagger UI: http://localhost:${port}/api/docs`);
  logger.log(`Runtime: Bun ${(globalThis as any).Bun?.version ?? "N/A"}`);
}

bootstrap();
