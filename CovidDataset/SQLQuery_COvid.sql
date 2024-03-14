--Select data we need
SELECT location, date, total_cases, new_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Population
SELECT location, date, population, total_cases, (CAST(total_cases AS float)/CAST(population AS float))*100 as DiseasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location='Spain'
ORDER BY 1,2

-- Finding Countries with highest infection rate
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((CAST(total_cases AS float)/CAST(population AS float)))*100 as InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionPercentage DESC

-- Finding Countries with highest death count and death rate
SELECT location, population, MAX(CAST(total_deaths as int)) as TotalDeathCount, MAX((CAST(total_deaths AS float)/CAST(population AS float)))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- Breaking total deaths down by continents
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL INFECTION AND DEATH NUMBERS

SELECT 
    date, 
    SUM(CAST(total_cases AS bigint)) AS GlobalTotalInfections, 
    SUM(CAST(total_deaths AS bigint)) AS GlobalTotalDeaths, 
    CASE 
        WHEN SUM(CAST(total_cases AS float)) > SUM(CAST(total_deaths AS float)) THEN 
            (SUM(CAST(total_deaths AS float)) / SUM(CAST(total_cases AS float))) * 100 
        ELSE 
            NULL -- Handle division by zero 
    END AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

--VACCINATIONS

--Population vs Vaccination (Rolling Count)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY location, date

--CTE for Percentage Vaccinated
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingCountVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, 
	CASE
		WHEN RollingCountVaccinations < population OR RollingCountVaccinations IS NULL THEN
			(RollingCountVaccinations/population)*100
		ELSE 
			100
	END AS PercentageVaccinated
FROM PopVsVac
WHERE location = 'Spain'

--Create view for data visualization

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated

--Tableau

--Table 1
SELECT SUM(CAST(total_cases AS bigint)) AS GlobalTotalInfections, SUM(CAST(total_deaths AS bigint)) AS GlobalTotalDeaths, 
	(SUM(CAST(total_deaths AS float)) / SUM(CAST(total_cases AS float))) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--Table 2
SELECT location, SUM(CAST(new_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT IN ('European Union', 'World', 'High Income', 'Upper middle income', 'Low income', 'Lower middle income')
GROUP BY location

--Table 3
SELECT location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC

--Table 4
SELECT location, Population, date, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY population, location, date
ORDER BY PercentPopulationInfected DESC
