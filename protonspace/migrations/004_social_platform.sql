-- ProtonSpace non-AI platform expansion. Safe to re-run.
CREATE TABLE IF NOT EXISTS proton_sessions (
  id CHAR(36) NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  character_id VARCHAR(64) NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY idx_proton_session_account (account_id), KEY idx_proton_session_expiry (expires_at),
  CONSTRAINT fk_proton_session_account FOREIGN KEY (account_id) REFERENCES proton_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS cover_url TEXT NULL;
ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT NULL;
ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS interests TEXT NULL;
ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS theme_json JSON NULL;
ALTER TABLE proton_profiles ADD COLUMN IF NOT EXISTS featured_friends_json JSON NULL;
ALTER TABLE proton_comments ADD COLUMN IF NOT EXISTS moderation_status ENUM('visible','pending','hidden','removed') NOT NULL DEFAULT 'visible';
ALTER TABLE proton_comments ADD COLUMN IF NOT EXISTS parent_comment_id BIGINT UNSIGNED NULL;

CREATE TABLE IF NOT EXISTS proton_bookmarks (
  account_id BIGINT UNSIGNED NOT NULL, post_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(account_id,post_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_blocks (
  blocker_account_id BIGINT UNSIGNED NOT NULL, blocked_account_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(blocker_account_id,blocked_account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_communities (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, public_id CHAR(26) NOT NULL, slug VARCHAR(100) NOT NULL,
  name VARCHAR(140) NOT NULL, description TEXT NULL, owner_account_id BIGINT UNSIGNED NOT NULL,
  visibility ENUM('public','private','invite') NOT NULL DEFAULT 'public', rules_text TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id), UNIQUE KEY uq_proton_community_public(public_id), UNIQUE KEY uq_proton_community_slug(slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_community_members (
  community_id BIGINT UNSIGNED NOT NULL, account_id BIGINT UNSIGNED NOT NULL,
  member_role ENUM('owner','admin','moderator','member') NOT NULL DEFAULT 'member',
  membership_status ENUM('active','pending','banned') NOT NULL DEFAULT 'active', joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(community_id,account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_conversations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, public_id CHAR(26) NOT NULL, conversation_type ENUM('direct','group') NOT NULL DEFAULT 'direct',
  title VARCHAR(140) NULL, created_by_account_id BIGINT UNSIGNED NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id), UNIQUE KEY uq_proton_conversation_public(public_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_conversation_members (
  conversation_id BIGINT UNSIGNED NOT NULL, account_id BIGINT UNSIGNED NOT NULL,
  last_read_at DATETIME NULL, muted_at DATETIME NULL, joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(conversation_id,account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, public_id CHAR(26) NOT NULL, conversation_id BIGINT UNSIGNED NOT NULL,
  sender_account_id BIGINT UNSIGNED NOT NULL, body TEXT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  edited_at DATETIME NULL, deleted_at DATETIME NULL,
  PRIMARY KEY(id), UNIQUE KEY uq_proton_message_public(public_id), KEY idx_proton_messages_conversation(conversation_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proton_cityos_links (
  account_id BIGINT UNSIGNED NOT NULL, citizenid VARCHAR(64) NOT NULL, display_character_publicly BOOLEAN NOT NULL DEFAULT FALSE,
  linked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(account_id,citizenid), UNIQUE KEY uq_proton_cityos_citizen(citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
