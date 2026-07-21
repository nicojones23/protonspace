CREATE TABLE IF NOT EXISTS proton_post_media (
  post_id BIGINT UNSIGNED NOT NULL,
  media_id BIGINT UNSIGNED NOT NULL,
  position_index INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY(post_id,media_id), KEY idx_proton_post_media_position(post_id,position_index),
  CONSTRAINT fk_proton_post_media_post FOREIGN KEY(post_id) REFERENCES proton_posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_proton_post_media_media FOREIGN KEY(media_id) REFERENCES proton_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE proton_media ADD COLUMN IF NOT EXISTS source_url TEXT NULL;
