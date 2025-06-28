-- Layoffs Data Cleaning Project

-- 1. Create staging table and insert data

CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;


-- 2. Remove duplicates using ROW_NUMBER

CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off TEXT,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions TEXT,
  row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off,
                 percentage_laid_off, date, stage, country, funds_raised_millions
  ) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- 3. Standardize text formatting

UPDATE layoffs_staging2
SET company = TRIM(company);

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- 4. Normalize NULL values

-- Replace empty strings or 'NULL' strings with actual NULLs
UPDATE layoffs_staging2
SET industry = NULL
WHERE TRIM(industry) = '' OR industry = 'NULL';

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE TRIM(total_laid_off) = '' OR total_laid_off = 'NULL';

UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE TRIM(percentage_laid_off) = '' OR percentage_laid_off = 'NULL';

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE TRIM(funds_raised_millions) = '' OR funds_raised_millions = 'NULL';

UPDATE layoffs_staging2
SET stage = NULL
WHERE TRIM(stage) = '' OR stage = 'NULL';

UPDATE layoffs_staging2
SET date = NULL
WHERE TRIM(date) = '' OR date = 'NULL';


-- 5. Convert and clean date format

UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y')
WHERE date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

UPDATE layoffs_staging2
SET date = NULL
WHERE date IS NOT NULL AND date NOT LIKE '____-__-__';

ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;


-- 6. Fill missing industry using self-join

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;


-- 7. Final cleanup: remove unusable rows

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


-- 8. Drop helper columns

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;