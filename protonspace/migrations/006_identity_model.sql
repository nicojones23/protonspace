-- Accounts authenticate. Identities publish. Permissions connect them.
CREATE TABLE IF NOT EXISTS proton_identities (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) NOT NULL,
  identity_type ENUM('personal','character','page') NOT NULL,
  username VARCHAR(80) NOT NULL,
  display_name VARCHAR(140) NOT NULL,
  avatar_url TEXT NULL,
  cover_url TEXT NULL,
  bio TEXT NULL,
  visibility ENUM('public','followers','private') NOT NULL DEFAULT 'public',
  show_on_owner_profile BOOLEAN NOT NULL DEFAULT FALSE,
  identity_status ENUM('active','restricted','retired') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(id), UNIQUE KEY uq_proton_identity_public(public_id), UNIQUE KEY uq_proton_identity_username(username),
  KEY idx_proton_identity_type(identity_type,identity_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_identity_members (
  identity_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  member_role ENUM('owner','administrator','editor','moderator','analyst') NOT NULL DEFAULT 'owner',
  can_view BOOLEAN NOT NULL DEFAULT TRUE,
  can_post BOOLEAN NOT NULL DEFAULT TRUE,
  can_edit_profile BOOLEAN NOT NULL DEFAULT TRUE,
  can_manage_relationships BOOLEAN NOT NULL DEFAULT TRUE,
  can_manage_settings BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(identity_id,account_id), KEY idx_proton_member_account(account_id,member_role),
  CONSTRAINT fk_proton_member_identity FOREIGN KEY(identity_id) REFERENCES proton_identities(id) ON DELETE CASCADE,
  CONSTRAINT fk_proton_member_account FOREIGN KEY(account_id) REFERENCES proton_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE proton_character_links ADD COLUMN IF NOT EXISTS identity_id BIGINT UNSIGNED NULL;
ALTER TABLE proton_character_links ADD COLUMN IF NOT EXISTS server_key VARCHAR(80) NOT NULL DEFAULT 'most_hated_rp';
ALTER TABLE proton_character_links ADD COLUMN IF NOT EXISTS transfer_locked BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE proton_sessions ADD COLUMN IF NOT EXISTS active_identity_id BIGINT UNSIGNED NULL;
ALTER TABLE proton_sessions ADD COLUMN IF NOT EXISTS identity_locked BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE proton_posts ADD COLUMN IF NOT EXISTS identity_id BIGINT UNSIGNED NULL;
ALTER TABLE proton_posts ADD COLUMN IF NOT EXISTS created_by_account_id BIGINT UNSIGNED NULL;
ALTER TABLE proton_posts MODIFY COLUMN author_type ENUM('account','personal','character','page','business','group','government','system') NOT NULL DEFAULT 'account';
ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS identity_id BIGINT UNSIGNED NULL;
ALTER TABLE proton_identities CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE proton_profiles ADD INDEX IF NOT EXISTS idx_proton_profile_account(account_id);
ALTER TABLE proton_profiles DROP INDEX IF EXISTS uq_proton_profile_account;

CREATE TABLE IF NOT EXISTS proton_identity_follows (
  follower_identity_id BIGINT UNSIGNED NOT NULL,
  followed_identity_id BIGINT UNSIGNED NOT NULL,
  created_by_account_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(follower_identity_id,followed_identity_id),
  KEY idx_proton_identity_followed(followed_identity_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_identity_link_codes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  code_hash CHAR(64) NOT NULL,
  citizenid VARCHAR(64) NULL,
  character_name VARCHAR(120) NULL,
  server_key VARCHAR(80) NOT NULL DEFAULT 'most_hated_rp',
  expires_at DATETIME NOT NULL,
  consumed_at DATETIME NULL,
  confirmed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id), UNIQUE KEY uq_proton_link_code_hash(code_hash), KEY idx_proton_link_code_expiry(expires_at,consumed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Every existing account receives one private-owner personal identity.
INSERT INTO proton_identities (public_id,identity_type,username,display_name)
SELECT LEFT(REPLACE(UUID(),'-',''),26),'personal',LEFT(CONCAT('p_',a.username),80),a.display_name
FROM proton_accounts a
WHERE NOT EXISTS (SELECT 1 FROM proton_identities i WHERE i.username=LEFT(CONCAT('p_',a.username),80));

INSERT IGNORE INTO proton_identity_members (identity_id,account_id,member_role)
SELECT i.id,a.id,'owner' FROM proton_accounts a JOIN proton_identities i ON i.username=LEFT(CONCAT('p_',a.username),80);

-- Existing verified characters become independent character identities.
INSERT INTO proton_identities (public_id,identity_type,username,display_name)
SELECT LEFT(REPLACE(UUID(),'-',''),26),'character',LEFT(CONCAT('c_',cl.citizenid),80),cl.character_name
FROM proton_character_links cl
WHERE cl.identity_id IS NULL AND NOT EXISTS (SELECT 1 FROM proton_identities i WHERE i.username=LEFT(CONCAT('c_',cl.citizenid),80));

UPDATE proton_character_links cl JOIN proton_identities i ON i.username=LEFT(CONCAT('c_',cl.citizenid),80)
SET cl.identity_id=i.id WHERE cl.identity_id IS NULL;

INSERT IGNORE INTO proton_identity_members (identity_id,account_id,member_role)
SELECT cl.identity_id,cl.account_id,'owner' FROM proton_character_links cl WHERE cl.identity_id IS NOT NULL;

-- Character-only legacy login records no longer appear as duplicate public personal profiles.
UPDATE proton_identities i JOIN proton_identity_members im ON im.identity_id=i.id
JOIN proton_accounts a ON a.id=im.account_id
SET i.identity_status='retired'
WHERE i.identity_type='personal' AND a.discord_id IS NULL AND a.username LIKE 'c\_%';

-- Preserve existing content by assigning it to the owner's personal identity.
UPDATE proton_posts p JOIN proton_identity_members im ON im.account_id=p.account_id
JOIN proton_identities i ON i.id=im.identity_id AND i.identity_type='personal'
SET p.identity_id=i.id,p.created_by_account_id=p.account_id WHERE p.identity_id IS NULL;

UPDATE proton_profiles p JOIN proton_identity_members im ON im.account_id=p.account_id
JOIN proton_identities i ON i.id=im.identity_id AND i.identity_type='personal'
SET p.identity_id=i.id WHERE p.identity_id IS NULL;

UPDATE proton_sessions s JOIN proton_identity_members im ON im.account_id=s.account_id
JOIN proton_identities i ON i.id=im.identity_id AND i.identity_type='personal'
SET s.active_identity_id=i.id WHERE s.active_identity_id IS NULL;

ALTER TABLE proton_character_links ADD UNIQUE INDEX IF NOT EXISTS uq_proton_character_identity(identity_id);
ALTER TABLE proton_sessions ADD INDEX IF NOT EXISTS idx_proton_session_identity(active_identity_id);
ALTER TABLE proton_posts ADD INDEX IF NOT EXISTS idx_proton_post_identity(identity_id,published_at);
ALTER TABLE proton_profiles ADD UNIQUE INDEX IF NOT EXISTS uq_proton_profile_identity(identity_id);
