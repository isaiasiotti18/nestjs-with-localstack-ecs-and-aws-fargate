import { Entity, PrimaryKey, Property, Enum, OptionalProps } from "@mikro-orm/core";

export enum TaskStatus {
  PENDING = "PENDING",
  IN_PROGRESS = "IN_PROGRESS",
  DONE = "DONE",
}

@Entity({ tableName: "tasks" })
export class Task {
  [OptionalProps]?: "createdAt" | "updatedAt" | "status";

  @PrimaryKey({ type: "uuid" })
  id: string = crypto.randomUUID();

  @Property({ length: 255 })
  title!: string;

  @Property({ type: "text", nullable: true })
  description?: string;

  @Enum({ items: () => TaskStatus, default: TaskStatus.PENDING })
  status: TaskStatus = TaskStatus.PENDING;

  @Property()
  createdAt: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updatedAt: Date = new Date();
}
