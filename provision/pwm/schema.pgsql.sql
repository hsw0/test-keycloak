/**
https://github.com/pwm-project/pwm/blob/1e5562f8a2ead15190d5a203bbc201f59504a5cd/server/src/main/java/password/pwm/util/db/DatabaseTable.java
    PWM_META,
    PWM_RESPONSES,
    USER_AUDIT,
    INTRUDER,
    TOKENS,
    OTP,
    PW_NOTIFY,
    CLUSTER_STATE,
*/

REVOKE ALL ON DATABASE "{{ pwm_db_database }}" FROM "public";
GRANT CONNECT ON DATABASE "{{ pwm_db_database }}" TO "{{ pwm_db_username }}";

REVOKE ALL ON SCHEMA "public" FROM "public";
GRANT USAGE ON SCHEMA "public" TO "{{ pwm_db_username }}";

ALTER DEFAULT PRIVILEGES GRANT INSERT,SELECT,UPDATE,DELETE ON TABLES TO "{{ pwm_db_username }}";

CREATE TABLE pwm_meta (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE pwm_responses (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE user_audit (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE intruder (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE tokens (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE otp (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE pw_notify (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);

CREATE TABLE cluster_state (
 id VARCHAR(128) NOT NULL PRIMARY KEY,
 value TEXT
);
