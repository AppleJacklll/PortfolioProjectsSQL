SELECT * FROM PortfolioProject1..CovidDeaths
ORDER BY 3, 4

SELECT * FROM PortfolioProject1..CovidVaccination
ORDER BY 3, 4

--Selecting data
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject1..CovidDeaths
ORDER BY 1, 2

--Total cases vs total deaths
SELECT location, date, total_cases, total_deaths, ((total_deaths/ total_cases) * 100) AS 'likelihood_of_dying'
FROM PortfolioProject1..CovidDeaths
WHERE location LIKE '%vietnam%'
ORDER BY 1, 2

--Total cases vs population
SELECT location, date, total_cases, population, ((total_cases/ population) * 100) AS 'percentage_of_infection'
FROM PortfolioProject1..CovidDeaths
WHERE location LIKE '%india%'
ORDER BY 1, 2

--Top 10 countries with highest infection rates
SELECT TOP 10 location, MAX(((total_cases/ population) * 100)) AS 'percentage_of_infection'
FROM PortfolioProject1..CovidDeaths
GROUP BY location
ORDER BY percentage_of_infection DESC

--Top 10 countries with highest death rates
SELECT TOP 10 location, ISNULL(MAX(((CAST(total_deaths AS INT)/ population) * 100)), 0) AS 'percentage_of_deaths'
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY percentage_of_deaths DESC

SELECT location, MAX(CAST(total_deaths AS INT)) AS 'number_of_deaths'
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY number_of_deaths DESC

--Deaths with continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS 'number_of_deaths'
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY number_of_deaths DESC

--Global numbers
SELECT date, SUM(new_cases) AS 'Global_new_cases', SUM(CAST(new_deaths AS INT)) AS 'Global_new_deaths', (SUM(CAST(new_deaths AS INT))/ SUM(new_cases) * 100) AS 'Death_percentage'
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC

SELECT SUM(new_cases) AS 'Global_new_cases', SUM(CAST(new_deaths AS INT)) AS 'Global_new_deaths', (SUM(CAST(new_deaths AS INT))/ SUM(new_cases) * 100) AS 'Death_percentage'
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL

--Inner join of CovidDeaths and CovidVaccination tables
SELECT *  FROM PortfolioProject1..CovidDeaths
JOIN PortfolioProject1..CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date

--Total population vs vaccination	
SELECT CovidDeaths.location, population, SUM(CAST(new_vaccinations AS INT)) AS 'Total vaccination', (SUM(CAST(new_vaccinations AS INT))/ population *100) FROM  CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL AND CovidDeaths.location LIKE '%srilanka%'
GROUP BY CovidDeaths.location, population
ORDER BY [Total vaccination] DESC

SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, ISNULL(CovidVaccination.new_vaccinations, 0)
FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL
ORDER BY 2, 3

SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, CovidVaccination.new_vaccinations,
SUM(CAST(new_vaccinations AS INT)) OVER(PARTITION BY CovidDeaths.location) FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL 
ORDER BY 2, 3

--Use CTE
WITH PopvsVac(contient, location, date, population, new_vaccinations, Total_vaccination_rolling)
AS
(
SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, CovidVaccination.new_vaccinations,
SUM(CAST(new_vaccinations AS INT)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date ) AS 'Total_vaccination_rolling'--, (Total_vaccination_rolling / population) * 100
FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT *, (Total_vaccination_rolling/population) * 100 FROM PopvsVac

--TEMP table
CREATE TABLE #precentVaccinated (
	continent VARCHAR(255),
	location VARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	Total_vaccination_rolling NUMERIC
	)
INSERT INTO #precentVaccinated
SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, CovidVaccination.new_vaccinations,
SUM(CAST(new_vaccinations AS INT)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date ) AS 'Total_vaccination_rolling'--, (Total_vaccination_rolling / population) * 100
FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (Total_vaccination_rolling/population) * 100 FROM #precentVaccinated 


DROP TABLE IF EXISTS #precentVaccinated --When you making any alteration it is useful
CREATE TABLE #precentVaccinated (
	continent VARCHAR(255),
	location VARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	Total_vaccination_rolling NUMERIC
	)
INSERT INTO #precentVaccinated
SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, CovidVaccination.new_vaccinations,
SUM(CAST(new_vaccinations AS INT)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date ) AS 'Total_vaccination_rolling'--, (Total_vaccination_rolling / population) * 100
FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
--WHERE CovidDeaths.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (Total_vaccination_rolling/population) * 100 FROM #precentVaccinated 

--Creating view to store data for later vizualization
CREATE VIEW precentVaccinated AS 
SELECT CovidDeaths.continent,  CovidDeaths.location, CovidDeaths.date, population, CovidVaccination.new_vaccinations,
SUM(CAST(new_vaccinations AS INT)) OVER(PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date ) AS 'Total_vaccination_rolling'--, (Total_vaccination_rolling / population) * 100
FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL
--ORDER BY 2, 3

CREATE VIEW TotalVaccination AS 
SELECT CovidDeaths.location, population, SUM(CAST(new_vaccinations AS INT)) AS 'Total vaccination', (SUM(CAST(new_vaccinations AS INT))/ population *100) AS 'Total_vaccination_percentage' FROM CovidDeaths
JOIN CovidVaccination
	ON CovidDeaths.location = CovidVaccination.location 
	AND CovidDeaths.date = CovidVaccination.date
WHERE CovidDeaths.continent IS NOT NULL 
GROUP BY CovidDeaths.location, population



