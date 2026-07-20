CREATE TABLE IF NOT EXISTS proton_accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) NOT NULL,
  username VARCHAR(40) NOT NULL,
  display_name VARCHAR(80) NOT NULL,
  email VARCHAR(190) NULL,
  password_hash VARCHAR(255) NULL,
  account_status ENUM('active','restricted','suspended','deleted') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_accounts_public_id (public_id),
  UNIQUE KEY uq_proton_accounts_username (username), UNIQUE KEY uq_proton_accounts_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_character_links (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  citizenid VARCHAR(64) NOT NULL,
  character_name VARCHAR(120) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  linked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_in_city_at DATETIME NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_character_citizenid (citizenid),
  KEY idx_proton_character_account (account_id),
  CONSTRAINT fk_proton_character_account FOREIGN KEY (account_id) REFERENCES proton_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_profiles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  slug VARCHAR(80) NOT NULL,
  headline VARCHAR(160) NULL,
  bio TEXT NULL,
  mood VARCHAR(80) NULL,
  location_label VARCHAR(120) NULL,
  visibility ENUM('public','friends','private') NOT NULL DEFAULT 'public',
  layout_version INT UNSIGNED NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_profile_account (account_id), UNIQUE KEY uq_proton_profile_slug (slug),
  CONSTRAINT fk_proton_profile_account FOREIGN KEY (account_id) REFERENCES proton_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_posts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) NOT NULL,
  author_type ENUM('account','character','business','group','government','system') NOT NULL DEFAULT 'account',
  author_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NULL,
  citizenid VARCHAR(64) NULL,
  post_type ENUM('status','image','article','event','business','city_event','live','app_share') NOT NULL DEFAULT 'status',
  body TEXT NOT NULL,
  visibility ENUM('public','followers','friends','group','private') NOT NULL DEFAULT 'public',
  moderation_status ENUM('visible','limited','hidden','removed') NOT NULL DEFAULT 'visible',
  published_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  edited_at DATETIME NULL, deleted_at DATETIME NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_post_public_id (public_id),
  KEY idx_proton_post_feed (published_at, moderation_status), KEY idx_proton_post_author (author_type, author_id, published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_comments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  public_id CHAR(26) NOT NULL, post_id BIGINT UNSIGNED NOT NULL, account_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, deleted_at DATETIME NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_comment_public_id (public_id), KEY idx_proton_comment_post (post_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_reactions (
  target_type ENUM('post','comment','profile_comment') NOT NULL, target_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL, reaction ENUM('like','love','fire','laugh','wow','clap') NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (target_type, target_id, account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_follows (
  follower_account_id BIGINT UNSIGNED NOT NULL, followed_account_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (follower_account_id, followed_account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS proton_notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, public_id CHAR(26) NOT NULL, account_id BIGINT UNSIGNED NOT NULL,
  notification_type VARCHAR(80) NOT NULL, title VARCHAR(160) NOT NULL, message TEXT NULL, route VARCHAR(255) NULL,
  read_at DATETIME NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_proton_notification_public_id (public_id), KEY idx_proton_notification_account (account_id, read_at, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rollback (only for a deliberate migration rollback):
-- DROP TABLE proton_notifications, proton_follows, proton_reactions, proton_comments, proton_posts, proton_profiles, proton_character_links, proton_accounts;
