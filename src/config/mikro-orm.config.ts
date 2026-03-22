import { defineConfig } from "@mikro-orm/postgresql";
import { Migrator } from "@mikro-orm/migrations";
import { Task } from "../tasks/entities/task.entity";

export default defineConfig({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 5432,
  dbName: process.env.DB_NAME || "app",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  entities: [Task],
  debug: process.env.NODE_ENV === "development",
  extensions: [Migrator],
  migrations: {
    path: "dist/migrations",
    pathTs: "src/migrations",
  },
});
