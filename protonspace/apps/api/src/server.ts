import { createServer, IncomingMessage, ServerResponse } from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import mysql from 'mysql2/promise';

const port = Number(process.env.PORT ?? 4080);
const origin = process.env.PROTONSPACE_WEB_ORIGIN ?? 'http://localhost:5173';
const cityosSecret = process.env.CITYOS_PROTON_TICKET_SECRET ?? '';
const pool = mysql.createPool(process.env.DATABASE_URL ?? 'mysql://cityos:CHANGE_ME@127.0.0.1/cityos_fivem');

type Session = { accountId: number; characterId?: string; expiresAt: number };
const sessions = new Map<string, Session>();
const tickets = new Map<string, { accountId: number; citizenId: string; expiresAt: number; used: boolean }>();

function json(res: ServerResponse, status: number, body: unknown) { res.writeHead(status, {'content-type':'application/json; charset=utf-8','access-control-allow-origin':origin,'access-control-allow-credentials':'true'}); res.end(JSON.stringify(body)); }
async function body(req: IncomingMessage) { let raw=''; for await (const chunk of req) raw += chunk; return raw ? JSON.parse(raw) : {}; }
function cookie(req: IncomingMessage, name: string) { return (req.headers.cookie ?? '').split(';').map(x=>x.trim()).find(x=>x.startsWith(name+'='))?.slice(name.length+1); }
function session(req: IncomingMessage) { const key=cookie(req,'proton_session'); const s=key?sessions.get(key):undefined; return s && s.expiresAt>Date.now()?s:null; }
function publicId() { return randomBytes(16).toString('hex').slice(0,26); }

async function route(req: IncomingMessage, res: ServerResponse) {
  if (req.method === 'OPTIONS') return json(res,204,{});
  const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
  if (req.method === 'GET' && url.pathname === '/health') return json(res,200,{ok:true,service:'protonspace-api'});
  if (req.method === 'POST' && url.pathname === '/api/auth/ticket/exchange') {
    const input=await body(req); const ticket=tickets.get(String(input.ticket ?? ''));
    if (!ticket || ticket.used || ticket.expiresAt<Date.now()) return json(res,401,{error:'invalid_ticket'});
    ticket.used=true; const sessionId=randomUUID(); sessions.set(sessionId,{accountId:ticket.accountId,characterId:ticket.citizenId,expiresAt:Date.now()+86400000});
    res.setHeader('set-cookie',`proton_session=${sessionId}; HttpOnly; SameSite=Lax; Path=/; Max-Age=86400`); return json(res,200,{ok:true,surface:'web'});
  }
  if (req.method === 'POST' && url.pathname === '/internal/cityos/tickets') {
    if (!cityosSecret || req.headers['x-cityos-ticket-secret'] !== cityosSecret) return json(res,403,{error:'forbidden'});
    const input=await body(req); const citizenId=typeof input.citizenId==='string'?input.citizenId.trim():''; const name=typeof input.characterName==='string'?input.characterName.trim():'';
    if(!citizenId||!name)return json(res,400,{error:'character_required'});
    const username=('c_'+citizenId).toLowerCase().replace(/[^a-z0-9_]/g,'').slice(0,40); const publicAccountId=publicId();
    await pool.query('INSERT INTO proton_accounts (public_id,username,display_name) VALUES (?,?,?) ON DUPLICATE KEY UPDATE display_name=VALUES(display_name)',[publicAccountId,username,name]);
    const [accounts]=await pool.query('SELECT id FROM proton_accounts WHERE username=? LIMIT 1',[username]); const accountId=Number((accounts as any[])[0]?.id); if(!accountId)return json(res,500,{error:'account_link_failed'});
    await pool.query('INSERT INTO proton_character_links (account_id,citizenid,character_name,is_primary,is_verified,last_seen_in_city_at) VALUES (?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE account_id=VALUES(account_id),character_name=VALUES(character_name),is_verified=VALUES(is_verified),last_seen_in_city_at=NOW()',[accountId,citizenId,name,true,true]);
    const ticket=randomUUID(); tickets.set(ticket,{accountId,citizenId,expiresAt:Date.now()+45000,used:false}); return json(res,200,{ticket,expiresIn:45,exchangePath:'/api/auth/ticket/exchange'});
  }
  const current=session(req); if (!current) return json(res,401,{error:'authentication_required'});
  if (req.method === 'GET' && url.pathname === '/api/me') { const [rows]=await pool.query('SELECT a.public_id AS publicId,a.username,a.display_name AS displayName,p.slug,p.headline,p.bio FROM proton_accounts a LEFT JOIN proton_profiles p ON p.account_id=a.id WHERE a.id=? AND a.account_status="active"',[current.accountId]); return json(res,200,{account:(rows as any[])[0] ?? null,characterId:current.characterId}); }
  if (req.method === 'GET' && url.pathname === '/api/feed') { const [rows]=await pool.query(`SELECT p.public_id AS publicId,p.body,p.author_type AS authorType,p.published_at AS publishedAt,a.username,a.display_name AS displayName FROM proton_posts p LEFT JOIN proton_accounts a ON a.id=p.account_id WHERE p.visibility='public' AND p.moderation_status='visible' AND p.deleted_at IS NULL ORDER BY p.published_at DESC LIMIT 100`); return json(res,200,{posts:rows}); }
  if (req.method === 'POST' && url.pathname === '/api/posts') { const input=await body(req); const text=typeof input.body==='string'?input.body.trim():''; if(!text||text.length>2000)return json(res,400,{error:'invalid_body'}); const [accountRows]=await pool.query('SELECT id FROM proton_accounts WHERE id=? AND account_status="active"',[current.accountId]); if(!(accountRows as any[]).length)return json(res,403,{error:'account_unavailable'}); const id=publicId(); await pool.query('INSERT INTO proton_posts (public_id,author_type,author_id,account_id,citizenid,body) VALUES (?,"account",?,?,?,?,?)',[id,current.accountId,current.accountId,current.characterId??null,text]); return json(res,201,{publicId:id}); }
  return json(res,404,{error:'not_found'});
}

createServer((req,res)=>{route(req,res).catch(err=>{console.error(err);json(res,500,{error:'internal_error'});});}).listen(port,()=>console.log(`[protonspace-api] listening on ${port}`));

// Called by the thin FiveM bridge after CityOS has verified a character. Never expose this endpoint publicly.
export function issueCityOSTicket(accountId:number,citizenId:string) { const ticket=randomUUID(); tickets.set(ticket,{accountId,citizenId,expiresAt:Date.now()+45000,used:false}); return ticket; }
