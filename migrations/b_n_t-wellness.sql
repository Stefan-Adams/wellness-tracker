-- 1 up

CREATE TABLE config(id integer primary key autoincrement, k text, v text);
CREATE TABLE participants (uid text primary key, last_name text, first_name text, enrollment_date text, email text, department text, team text, consent text, birthday text, gender text);
CREATE TABLE assessment_types (id integer primary key autoincrement, c text);

-- 1 down

DROP TABLE config;
DROP TABLE participants;
DROP TABLE assessment_types;
