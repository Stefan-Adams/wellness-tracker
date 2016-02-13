-- 1 up

CREATE TABLE participants (uid text primary key, last_name text, first_name text, enrollment_date text, email text, department text, team text, consent text, birthday text, gender text);
CREATE TABLE surveys (id integer primary key autoincrement, uid text, date text, k text, v text);
CREATE TABLE measurements (id integer primary key autoincrement, uid text, date text, k text, v text);
CREATE TABLE pcp_visits (id integer primary key autoincrement, uid text, date text, k text, v text);
CREATE TABLE fitness_tests (id integer primary key autoincrement, uid text, date text, k text, v text);
CREATE TABLE fitbit_steps (id integer primary key autoincrement, uid text, date text, k text, v text);
CREATE TABLE points (id integer primary key autoincrement, uid text, date text, c text, k text, v text);
CREATE TABLE assessment_types (id integer primary key autoincrement, c text);

-- 1 down

DROP TABLE participants;
DROP TABLE surveys;
DROP TABLE measurements;
DROP TABLE pcp_visits;
DROP TABLE fitness_tests;
DROP TABLE points;
DROP TABLE assessment_types;
