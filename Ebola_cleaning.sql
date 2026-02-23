SELECT *
FROM nndss_ebola;

## Generate staging table 

CREATE TABLE e_staging1
LIKE nndss_ebola;

INSERT e_staging1
SELECT *
FROM nndss_ebola;

SELECT *
FROM e_staging1;

## Remove dupes - unneeded

SELECT *,
ROW_NUMBER() OVER(ORDER BY sort_order ASC) as row_num
FROM e_staging1;	

## Standardize data - U.S. to US 

SELECT *
FROM e_staging1
WHERE `Reporting Area` LIKE "%Common%";	


-- Capitalize it all --
UPDATE e_staging1
SET `Reporting Area` = UPPER(`Reporting Area`);

UPDATE e_staging1
SET LOCATION1 = UPPER(LOCATION1);

UPDATE e_staging1
SET LOCATION2 = UPPER(LOCATION2);

-- U.S. to US --
UPDATE e_staging1
SET `Reporting Area` = REPLACE(`Reporting Area`, '.', '');

UPDATE e_staging1
SET LOCATION1 = REPLACE(LOCATION1, '.', '');

UPDATE e_staging1
SET LOCATION2 = REPLACE(LOCATION2, '.', '');

SELECT *
FROM e_staging1
WHERE `Reporting Area` LIKE "%U.S.%";	

SELECT *
FROM e_staging1
WHERE LOCATION1 LIKE "%U.S.%";	

SELECT *
FROM e_staging1
WHERE LOCATION2 LIKE "%U.S.%";	

## Null and Blank assessment

-- Without previous or current cumulutaive data is not helpful. drop 
SELECT *
FROM e_staging1
WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1;

CREATE TABLE e_staging2
LIKE e_staging1;

INSERT e_staging2
SELECT *
FROM e_staging1;

SELECT *
FROM e_staging2;

DELETE FROM e_staging2
WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1;

SELECT *
FROM e_staging2;
-- WHERE geocode = '' AND `Previous 52 week Max` < 1 AND `Cumulative YTD Current MMWR Year` < 1 AND `Cumulative YTD Previous MMWR Year` < 1-- 

WITH all_locations AS (
    SELECT TRIM(LOCATION1) AS loc FROM e_staging2 WHERE LOCATION1 IS NOT NULL AND TRIM(LOCATION1) <> ''
    UNION
    SELECT TRIM(LOCATION2) AS loc FROM e_staging2 WHERE LOCATION2 IS NOT NULL AND TRIM(LOCATION2) <> ''
),

location_master_list AS (
    SELECT loc, DENSE_RANK() OVER (ORDER BY loc) AS location_id
    FROM all_locations
)

SELECT base.*, COALESCE(map1.location_id, map2.location_id) AS location_id
FROM e_staging2 AS base
LEFT JOIN location_master_list AS map1 
    ON TRIM(base.LOCATION1) = map1.loc
LEFT JOIN location_master_list AS map2 
    ON TRIM(base.LOCATION2) = map2.loc;

SELECT * 
FROM e_staging2
WHERE `Reporting Area` != LOCATION1;

-- Location1 and Location2 were repeats of reporting areas --
ALTER TABLE e_staging2
DROP COLUMN LOCATION1,
DROP COLUMN LOCATION2;

CREATE TABLE e_staging3
LIKE e_staging2;

INSERT e_staging3
SELECT *
FROM e_staging2;

SELECT *
FROM e_staging3;

DELETE FROM e_staging3
WHERE TRIM(geocode) ='';

SELECT *, DENSE_RANK() OVER (ORDER BY `Reporting Area`) as Report_Num
FROM e_staging3
WHERE `Reporting Area` IS NOT NULL 
	AND TRIM(`Reporting Area`) <> '' 
ORDER BY `Reporting Area` ASC;

ALTER TABLE e_staging3
ADD area_id INT,
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

UPDATE e_staging3 T
JOIN (
    SELECT id, DENSE_RANK() OVER (ORDER BY `Reporting Area` ASC) AS Report_Num
    FROM e_staging3
) AS R ON T.id = R.id
SET T.area_id = R.Report_Num;

ALTER TABLE e_staging3
RENAME COLUMN id TO unique_id;

-- Rearrange column order, drop label and sort_order as they are redundant information here
ALTER TABLE e_staging3
DROP COLUMN LABEL,
DROP COLUMN sort_order;

SELECT * 
FROM e_staging3
ORDER BY area_id ASC, `Current MMWR Year` ASC, `MMWR WEEK` ASC;

CREATE TABLE ebola_cleaned AS
SELECT *
FROM e_staging3
ORDER BY area_id ASC, `Current MMWR Year` ASC, `MMWR WEEK` ASC;


SELECT * FROM nndss_dhhs_weekly_data.ebola_cleaned;

-- Prelim Check --

SELECT DISTINCT `Current week, flag`
FROM ebola_cleaned;

SELECT DISTINCT `Previous 52 weeks Max, flag`
FROM ebola_cleaned;

SELECT DISTINCT `Cumulative YTD Current MMWR Year, flag`
FROM ebola_cleaned;

SELECT DISTINCT `Cumulative YTD Previous MMWR Year, flag`
FROM ebola_cleaned;

ALTER TABLE ebola_cleaned COMMENT = "U: Unavailable — The reporting jurisdiction was unable to send the data to CDC or CDC was unable to process the data.
-: No reported cases — The reporting jurisdiction did not submit any cases to CDC.
N: Not reportable — The disease or condition was not reportable by law, statute, or regulation in the reporting jurisdiction.
NN: Not nationally notifiable — This condition was not designated as being nationally notifiable.
NP: Nationally notifiable but not published.
NC: Not calculated — There is insufficient data available to support the calculation of this statistic.
Cum: Cumulative year-to-date counts.
Max: Maximum — Maximum case count during the previous 52 weeks.";

















































































































































































































































































































































































































































































































