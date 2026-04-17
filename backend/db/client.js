import dotenv from 'dotenv';
import postgres from 'postgres';

dotenv.config();

const connectionString = process.env.DATABASE_URL || process.env.SUPABASE_DB_URL;

if (!connectionString) {
  throw new Error('Missing DATABASE_URL or SUPABASE_DB_URL');
}

const sql = postgres(connectionString, {
  ssl: 'require',
});

export default sql;
export const db = {
  query(text, params = []) {
    return sql.unsafe(text, params).then((rows) => ({ rows }));
  },
  end() {
    return sql.end({ timeout: 5 });
  },
};

export async function query(text, params = []) {
  const rows = await sql.unsafe(text, params);
  return { rows };
}

export async function end() {
  await sql.end({ timeout: 5 });
}
