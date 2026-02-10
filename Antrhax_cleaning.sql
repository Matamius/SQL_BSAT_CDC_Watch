SELECT *
FROM nndss_anthrax;

## Generate staging table 

CREATE TABLE a_staging1
LIKE nndss_anthrax;

INSERT a_staging1
SELECT *
FROM nndss_anthrax;

SELECT *
FROM a_staging1;

## Remove dupes - unneeded

SELECT *,
ROW_NUMBER() OVER(ORDER BY sort_order ASC) as row_num
FROM a_staging1;	

## Standardize data - U.S. to US 

SELECT *
FROM a_staging1
WHERE `Reporting Area` LIKE "%Common%";	


-- Capitalize it all --
UPDATE a_staging1
SET `Reporting Area` = UPPER(`Reporting Area`);

UPDATE a_staging1
SET LOCATION1 = UPPER(LOCATION1);

UPDATE a_staging1
SET LOCATION2 = UPPER(LOCATION2);

-- U.S. to US --
UPDATE a_staging1
SET `Reporting Area` = REPLACE(`Reporting Area`, '.', '');

UPDATE a_staging1
SET LOCATION1 = REPLACE(LOCATION1, '.', '');

UPDATE a_staging1
SET LOCATION2 = REPLACE(LOCATION2, '.', '');

SELECT *
FROM a_staging1
WHERE `Reporting Area` LIKE "%U.S.%";	

SELECT *
FROM a_staging1
WHERE LOCATION1 LIKE "%U.S.%";	

SELECT *
FROM a_staging1
WHERE LOCATION2 LIKE "%U.S.%";	

## Null and Blank assessment

-- Without previous or current cumulutaive data is not helpful. drop 
SELECT *
FROM a_staging1
WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1;

CREATE TABLE a_staging2
LIKE a_staging1;

INSERT a_staging2
SELECT *
FROM a_staging1;

SELECT *
FROM a_staging2;

DELETE FROM a_staging2
WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1;

SELECT *
FROM a_staging2;
-- WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1-- 

SELECT TRIM(LOCATION1), dense_rank() OVER (ORDER BY LOCATION1) as location1_num
FROM a_staging2
WHERE LOCATION1 IS NOT NULL 
	AND LOCATION1 <> '' 
    AND LOCATION1 <> ' ' 
ORDER BY LOCATION1 ASC;

SELECT TRIM(LOCATION2), dense_rank() OVER (ORDER BY LOCATION2) as location2_num
FROM a_staging2
WHERE LOCATION2 IS NOT NULL 
	AND LOCATION2 <> '' 
    AND LOCATION2 <> ' '
    AND LOCATION2 <> 'TOTAL'
ORDER BY LOCATION2 ASC;

SELECT *, dense_rank() OVER (ORDER BY LOCATION1) as location1_num
FROM a_staging2
WHERE LOCATION1 IS NOT NULL 
	AND LOCATION1 <> '' 
    AND LOCATION1 <> ' ' 
ORDER BY LOCATION1 ASC;

SELECT * 
FROM a_staging2
WHERE `Reporting Area` != LOCATION1;

-- Location1 and Location2 were repeats of reporting area, consider dropping all records with no geocode (i.e., where no reporting area was strictly identified) does not yield productive results --
ALTER TABLE a_staging2
DROP COLUMN LOCATION1,
DROP COLUMN LOCATION2,
DROP COLUMN MyUnknownColumn,
DROP COLUMN `MyUnknownColumn_[0]`;

CREATE TABLE a_staging3
LIKE a_staging2;

INSERT a_staging3
SELECT *
FROM a_staging2;

SELECT *
FROM a_staging3;

DELETE FROM a_staging3
WHERE geocode ='';

SELECT *, DENSE_RANK() OVER (ORDER BY `Reporting Area`) as Report_Num
FROM a_staging3
WHERE `Reporting Area` IS NOT NULL 
	AND `Reporting Area` <> '' 
    AND `Reporting Area` <> ' ' 
ORDER BY `Reporting Area` ASC;

ALTER TABLE a_staging3
ADD area_id INT,
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

UPDATE a_staging3 T
JOIN (
    SELECT id, DENSE_RANK() OVER (ORDER BY `Reporting Area` ASC) AS Report_Num
    FROM a_staging3
) AS R ON T.id = R.id
SET T.area_id = R.Report_Num;

ALTER TABLE a_staging3
RENAME COLUMN id TO unique_id;

-- Rearrange column order, drop label and sort_order as they are redundant information here
ALTER TABLE a_staging3
DROP COLUMN LABEL,
DROP COLUMN sort_order;

SELECT * 
FROM a_staging3
ORDER BY area_id ASC, `Current MMWR Year` ASC, `MMWR WEEK` ASC;

CREATE TABLE anthrax_cleaned AS
SELECT *
FROM a_staging3
ORDER BY area_id ASC, `Current MMWR Year` ASC, `MMWR WEEK` ASC;


SELECT * FROM nndss_dhhs_weekly_data.anthrax_cleaned;

-- Prelim Check --

SELECT DISTINCT `Current week, flag`
FROM anthrax_cleaned;

SELECT DISTINCT `Previous 52 weeks Max, flag`
FROM anthrax_cleaned;

SELECT DISTINCT `Cumulative YTD Current MMWR Year, flag`
FROM anthrax_cleaned;

SELECT DISTINCT `Cumulative YTD Previous MMWR Year, flag`
FROM anthrax_cleaned;

ALTER TABLE anthrax_cleaned COMMENT = "U: Unavailable — The reporting jurisdiction was unable to send the data to CDC or CDC was unable to process the data.
-: No reported cases — The reporting jurisdiction did not submit any cases to CDC.
N: Not reportable — The disease or condition was not reportable by law, statute, or regulation in the reporting jurisdiction.
NN: Not nationally notifiable — This condition was not designated as being nationally notifiable.
NP: Nationally notifiable but not published.
NC: Not calculated — There is insufficient data available to support the calculation of this statistic.
Cum: Cumulative year-to-date counts.
Max: Maximum — Maximum case count during the previous 52 weeks.";

















































































































































































































































































































































































































































































































