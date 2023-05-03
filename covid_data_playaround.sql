select* FROM portfolio.cd2021 cd
WHERE continent IS NOT NULL;


ALTER date_n AS (convert(varchar, date, 3) FROM cd2021;

SELECT DATA_TYPE FROM portfolio.cd2021
  WHERE table_name = 'cd2021' AND COLUMN_NAME = 'date';

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM cd2021 cd
ORDER BY 1, STR_TO_DATE(cd.date, '%d/%m/%y');

--Looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/ total_cases)*100 as DeathPercentage
FROM portfolio.cd2021 cd
WHERE location LIKE '%states%' AND (STR_TO_DATE(cd.date, '%d/%m/%y') BETWEEN '28-01-2020' AND '30-04-2021')
ORDER BY 1, STR_TO_DATE(cd.date, '%d/%m/%y');


---likelyhood of you contracting covid and dying in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/ total_cases)*100 as DeathPercentage
FROM portfolio.cd2021 cd
WHERE cd.date REGEXP '20|21$' AND location = 'United States'
ORDER BY 1, STR_TO_DATE(cd.date, '%d/%m/%y');

-- Looking at total cases vs population
-- Shows what poulation got covid
SELECT location, date, population, total_deaths, total_cases/population*100 AS infection_rate
FROM portfolio.cd2021 cd
WHERE cd.date REGEXP '20|21$' AND location = 'India'
ORDER BY 1, STR_TO_DATE(cd.date, '%d/%m/%y');

--highest infection rate country wise
SELECT location, population, MAX(total_cases) AS Highest_infection_count, MAX(total_cases/population)*100 AS infection_rate
FROM portfolio.cd2021 cd
WHERE cd.date REGEXP '20|21$' AND population>=  9000000
GROUP BY location, population
ORDER BY infection_rate DESC;

--countries with highest death count per population:
SELECT location, MAX(total_deaths) AS totaldeathcount
FROM portfolio.cd2021
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC;


-- break things by continent

-- showing the continents with highest death count
SELECT continent, MAX(total_deaths) AS totaldeathcount
FROM portfolio.cd2021
WHERE continent NOT LIKE ''
GROUP BY continent
ORDER BY totaldeathcount DESC;

-- drill down in tableau

-- Global numbers
SELECT SUM(new_cases) Total_cases, SUM(new_deaths) Total_deaths, 100 *SUM(new_deaths)/ SUM(new_cases) AS death_percentage
FROM portfolio.cd2021 cd
WHERE continent NOT LIKE ''
-- GROUP BY YEAR(cd.date)
ORDER BY STR_TO_DATE(cd.date, '%d/%m/%y');



SELECT *
FROM portfolio.cd2021 dea
JOIN portfolio.vac2021 vac
  ON dea.location= vac.location 
  AND dea.date= vac.date;

--Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM portfolio.cd2021 dea
  JOIN portfolio.vac2021 vac
    ON dea.location= vac.location 
    AND dea.date= vac.date
WHERE dea.continent <> ''
ORDER BY 1, 2;


-- Cumulitive count of vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%y')) AS cumulative
FROM portfolio.cd2021 dea
  JOIN portfolio.vac2021 vac
    ON dea.location= vac.location 
    AND dea.date= vac.date
WHERE dea.continent <> ''
ORDER BY 2, cumulative, STR_TO_DATE(dea.date, '%d/%m/%y');


-- Looking at vaccine vs population; 
--Use cte || Ensure number of colums in cte is the same as number of colums in select in the paraenthesis
WITH PopvsVac(continent, location, date, population, new_vaccinations, cumulative_people_vaccinated)
AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%y')) AS cumulative_people_vaccinated
    FROM portfolio.cd2021 dea
        JOIN portfolio.vac2021 vac
    ON dea.location= vac.location 
    AND dea.date= vac.date
    WHERE dea.continent <> ''
    -- ORDER BY 2, cumulative, STR_TO_DATE(dea.date, '%d/%m/%y');
)

SELECT*, 100*(cumulative_people_vaccinated/population) Percentage_pop_vaccinated
FROM PopvsVac;

-- ------------------------------------------
-- use a temp_table for above operation ---- INCOMPLETE
-- ------------------------------------------
DROP TABLE IF exists #Percentage_pop_vaccinated
CREATE TABLE #Percentage_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date DATETIME,
population numeric,
new_vaccinations numeric,
cumulative_people_vaccinated numeric
)

INSERT INTO Percentage_pop_vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%y')) AS cumulative_people_vaccinated
    FROM portfolio.cd2021 dea
      JOIN portfolio.vac2021 vac
        ON dea.location= vac.location 
          AND dea.date= vac.date
    WHERE dea.continent <> ''
    -- ORDER BY 2, cumulative, STR_TO_DATE(dea.date, '%d/%m/%y');

SELECT*, 100*(cumulative_people_vaccinated/population)
FROM Percentage_pop_vaccinated;




-- Creating view to store data for later visualization
DROP VIEW Percentage_pop_vaccinated;
CREATE VIEW Percentage_pop_vaccinated AS(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%y')) AS cumulative_people_vaccinated
  FROM portfolio.cd2021 dea
  JOIN portfolio.vac2021 vac
    ON dea.location= vac.location 
    AND dea.date= vac.date
  WHERE dea.continent <> ''
)
-- ORDER BY 2, cumulative, STR_TO_DATE(dea.date, '%d/%m/%y')