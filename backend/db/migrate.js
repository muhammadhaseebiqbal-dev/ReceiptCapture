import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import sqlClient, { end } from './client.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const migrationsDir = path.join(__dirname, 'migrations');

async function ensureMigrationsTable() {
  await sqlClient`
    create table if not exists schema_migrations (
      id serial primary key,
      filename text unique not null,
      applied_at timestamptz not null default now()
    )
  `;
}

async function getAppliedMigrations() {
  const result = await sqlClient`select filename from schema_migrations`;
  return new Set(result.map((row) => row.filename));
}

async function runMigrations() {
  await ensureMigrationsTable();

  const files = (await fs.readdir(migrationsDir))
    .filter((name) => name.endsWith('.sql'))
    .sort();

  const applied = await getAppliedMigrations();

  for (const file of files) {
    if (applied.has(file)) {
      continue;
    }

    const sqlPath = path.join(migrationsDir, file);
    const migrationSql = await fs.readFile(sqlPath, 'utf8');

    try {
      await sqlClient.begin(async (tx) => {
        await tx.unsafe(migrationSql);
        await tx`insert into schema_migrations (filename) values (${file})`;
      });
      console.log(`Applied migration: ${file}`);
    } catch (error) {
      console.error(`Failed migration: ${file}`);
      throw error;
    }
  }
}

runMigrations()
  .then(async () => {
    await end();
    console.log('Migrations complete');
  })
  .catch(async (error) => {
    await end();
    console.error(error);
    process.exit(1);
  });
