SELECT * FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT * FROM PortfolioProject..CovidVaccinations 
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases and Total Deaths
-- Shown likelyhood of dying if you contract covid in your country
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	CASE
		WHEN total_cases = 0 THEN NULL
		ELSE (total_deaths / NULLIF(total_cases, 0)) * 100
    END as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Total Cases + Population
-- Show what % of population got Covid
SELECT 
	location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%state%'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compard to Population
SELECT 
	location, 
	population, 
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population))*100 as PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected desc

-- Showing Countries with Highest Death Count per Population
SELECT 
	location, 
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount desc

-- BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT 
	continent, 
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS
SELECT  
    date, 
    SUM(new_cases) as total_cases, 
    SUM(cast(new_deaths as int)) as total_deaths, 
    CASE WHEN SUM(new_cases) <> 0 
        THEN SUM(cast(new_deaths as int))/SUM(new_cases)*100 
        ELSE 0 
    END as DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Looking at Total population and Vaccinations

-- TEMP TABLE
-- First, drop the table if it exists
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

-- Create the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated bigint
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(ISNULL(CONVERT(bigint, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;
--WHERE dea.continent is not null
--ORDER BY 2,3


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

