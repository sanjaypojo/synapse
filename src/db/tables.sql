CREATE TABLE syn_user (
  id serial PRIMARY KEY,
  fb_id bigint UNIQUE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  email varchar(120) UNIQUE NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  gender varchar(10)
    CHECK (gender IN ('male', 'female', 'other')),
  timezone numeric,
  is_hiring boolean DEFAULT FALSE,
  seeker_type varchar NOT NULL  DEFAULT 'passive'
    CHECK (seeker_type IN ('active', 'passive')),
  active boolean NOT NULL DEFAULT TRUE,
  softtime timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
