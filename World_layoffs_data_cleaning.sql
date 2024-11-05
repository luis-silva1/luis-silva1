# Data Cleaning

SELECT *
FROM layoffs;

# 1. Remove Duplicates
# 2. Standardized the Data(Spelling)
# 3. NULL values or blank values
# 4. Remove Columns that are not necessary

-- Creates a temporary table to manipulate
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Inserts data from layoffs table into our temporary table
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Check new table for data
SELECT *
FROM layoffs_staging;

-- 1. Remove Duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Create a CTE to check duplicate rows with partition by looking for identical entries
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Hibob';

-- Create a second table with row num to delete duplicates
-- > Right-click original table(layoffs)
-- > Copy to Clipboard
-- > Create Statement
-- > Paste (CTRL + V) onto script
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Delete duplicate rows from new table
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Check new table for non-duplicate entries
SELECT *
FROM layoffs_staging2;

-- 
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- 2. Standardizing Data

-- Check Company column for any extra spaces 
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Update table to remove extra spaces in Company column
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check table for different variations of industry name (Crypto, Crypto Currency)
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Update table to remove redundant industry names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check table for different variations of country name and remove trailing '.'
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Updates tables country name by removing period
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Updates table date from string to date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Changes `date` type from string to DATE type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Check table after updates
SELECT *
FROM layoffs_staging2;

-- 3. Null Values

-- Check data for NULL values in our 2 important columns
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Check data for incomplete industry to try to fill in NULL value
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Check Airbnb for other rows that could have industry name not NULL
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Compares table to itslef to compare null and empty values
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Update empty values in industry column with null 
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Updates industry null values to not null
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- Check Data for Null values in both total_laid_off and percantage_laid_off
SELECT *
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND  (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- Delete Null values with both empty columns
DELETE 
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND  (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- Delete Unecessary Columns
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Check final data after cleaning
SELECT *
FROM layoffs_staging2;




