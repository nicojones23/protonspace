ALTER TABLE proton_accounts ADD COLUMN discord_id VARCHAR(32) NULL;
ALTER TABLE proton_accounts ADD UNIQUE KEY uq_proton_accounts_discord_id (discord_id);
