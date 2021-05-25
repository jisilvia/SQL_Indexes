-- Create a database named lesson_exercises to store our state_names table
CREATE DATABASE lesson_exercises;

-- Activate the lesson_exercises database
USE lesson_exercises;

-- Create the state_names table with only a primary key index
CREATE TABLE state_names (
    state_name_id INT NOT NULL,
    name VARCHAR(255),
    year INT(4),
    gender ENUM('F','M'),
    state VARCHAR(2),
    name_count INT,
    PRIMARY KEY (state_name_id)
);


-- Add the ability for the admin user to set session values to allow mysqlimport to run
GRANT SESSION_VARIABLES_ADMIN ON *.* TO 'admin'@'%';


-- Run mysqlimport from the command line to import the state_names.csv file into the state_names table
SELECT *
FROM state_names 
LIMIT 10;

SELECT COUNT(*)
FROM state_names;

-- Benchmark query performance before adding an index

-- One column in WHERE
-- Run 3x and record the query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Jane';

-- 1: 1.986s
-- 2: 1.845s
-- 3: 1.576s


-- Two columns in WHERE
-- Run 3x and record the query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;

-- 1: 1.690s
-- 2: 1.984s
-- 3: 2.700s


-- Add an index on name
-- To make lookups based on name faster
CREATE INDEX index_name on state_names (name);

-- Confirm index added
SHOW INDEX FROM state_names;

DESCRIBE state_names; 


-- One column in WHERE
-- Run 3x and record the results and query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Jane';

-- Results: 
-- 1: 186ms
-- 2: 158ms
-- 3: 168ms


-- Two columns in WHERE
-- Run 3x and record the results and query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;

-- Results: 
-- 1: 305ms
-- 2: 171ms
-- 3: 174ms

/*
EXPLAIN
	- Shows the query execution plan
	- Confirms which indexes, if any, will be used

https://dev.mysql.com/doc/refman/8.0/en/using-explain.html
https://dba.stackexchange.com/questions/164251/what-is-the-meaning-of-filtered-in-mysql-explain
*/

-- Show the query execution plan with two columns in the WHERE
EXPLAIN
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;


-- Add a second index using year
CREATE INDEX index_year ON state_names (year);

-- Confirm index added
SHOW INDEX FROM state_names;

DESCRIBE state_names; 

-- Two columns in WHERE
-- Run 3x and record the results and query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;

-- 1: 202ms
-- 2: 189ms
-- 3: 185ms


-- Show the query execution plan with two columns in the WHERE after adding the second index
EXPLAIN 
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;


/*
Cardinality

High cardinality: many distinct values
Low cardinality: few distinct values
-- yes/no, male/female...

Only add index if high cardinality 
*/

-- Display index stats
SHOW INDEX FROM state_names;
-- 'name' has high cardinality -> added index 
-- 'year' has low cardinality -> no index necessary (still created one here)

-- Count the # of unique name values
SELECT COUNT(DISTINCT(name))
FROM state_names; 
-- SHOW INDEX may not always be accurate in finding unique values -> always perform COUNT(UNIQUE) first 


-- Count the # of unique year values
SELECT COUNT(DISTINCT(year))
FROM state_names; 


/*
Multiple Column (Composite) Indexes

If we wanted to query based on name and year, MySQL will return results faster 
if using 1 index with both columns versus 2 separate indexes for each column.

When creating the index, list the columns in the order based on frequency use.
The order determines if the index will be used. 

If name is listed first but not used in the WHERE, the composite index will not 
be used even if year is part of the index and year is in the WHERE

-- Add multiple columns to the index if columns are frequently used together in WHERE
-- List the columns in the index based on freqency usage 
*/

-- Add a single, composite index referencing two columns
CREATE INDEX index_name_year ON state_names (name, year);
-- year is more often queried with name instead of by itself

-- Show the updated query execution plan for two columns in the WHERE
EXPLAIN 
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;
-- the more indexes, the fewer rows SQL needs to look through
	

-- Two columns in WHERE
-- Run 3x and record the results and query time
SELECT COUNT(*)
FROM state_names 
WHERE name = 'Angel'
	AND `year` = 1979;

-- Results: 
-- 1: 159ms
-- 2: 156ms
-- 3: 173ms


-- Drop individual indexes on name and year
-- Unecessary indexes should be dropped; Ex: dropping independent indexes for columns that are queried together 
-- Can take a long time and will lock table
DROP INDEX index_name ON state_names;

DROP INDEX index_year ON state_names;

SHOW INDEX FROM state_names;
