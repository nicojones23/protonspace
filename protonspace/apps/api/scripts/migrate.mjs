import { readFile } from 'node:fs/promises';
import mysql from 'mysql2/promise';

const migration = process.argv[2];
if (!migration) throw new Error('Usage: node scripts/migrate.mjs <migration.sql>');

const envText = await readFile(new URL('../.env', import.meta.url), 'utf8').catch(() => '');
for (const line of envText.split(/\r?\n/)) {
  const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
  if (match && !process.env[match[1]]) process.env[match[1]] = match[2].replace(/^['"]|['"]$/g, '');
}

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not configured');
const sql = await readFile(migration, 'utf8');
const databaseUrl = new URL(process.env.DATABASE_URL);
const connection = await mysql.createConnection({host:databaseUrl.hostname,port:Number(databaseUrl.port||3306),user:decodeURIComponent(databaseUrl.username),password:decodeURIComponent(databaseUrl.password),database:databaseUrl.pathname.slice(1),multipleStatements:true});
await connection.query(sql);
await connection.end();
console.log(`Applied ${migration}`);
