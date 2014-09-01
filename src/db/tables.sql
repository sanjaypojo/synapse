CREATE TABLE syn_user (
  id serial PRIMARY KEY,
  linkedin_id integer UNIQUE NOT NULL,
  email varchar(120) UNIQUE NOT NULL,
  name text NOT NULL,
  is_hiring boolean NOT NULL DEFAULT FALSE,
  seeker_type varchar(10) NOT NULL
    CHECK (seeker_type IN ('active', 'passive')),
  active boolean NOT NULL DEFAULT TRUE,
  softtime timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
