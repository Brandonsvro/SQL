SELECT * FROM CovidDeaths
ORDER BY 3,4

SELECT * FROM CovidVaccinations
ORDER BY 3,4

-- Select data that we are going to use

SELECT location, 
		date, 
		total_cases, 
		total_deaths, 
		population
FROM CovidDeaths
ORDER BY 1,2

-- Total Cases VS Total Deaths (shows likelihood of dying if you contract covid in your country)

SELECT location, 
		date, 
		total_cases, 
		total_deaths, 
		(total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like 'Indonesia'
ORDER BY 1,2

-- Looking at Total Cases VS Population (shows that percentage of population got covid)

SELECT location, 
		date, 
		population, total_cases, 
		(total_cases/population)*100 as CasesPercentage
FROM CovidDeaths
--WHERE location like 'Indonesia'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT location, 
		population, 
		MAX(total_cases) as HighestInfect, 
		MAX((total_cases/population)*100) as PercentagePopInfect
FROM CovidDeaths
--WHERE location like 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentagePopInfect DESC

-- Show countries with highest death count per population

SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM CovidDeaths
--WHERE location like 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LETS BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM CovidDeaths
--WHERE location like 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBER

SELECT SUM(new_cases) as total_cases, 
		SUM(CAST(new_deaths as INT)) as total_death, 
		SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Total Populations VS Total Vaccinations

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingCountVac)
as(
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVac
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (RollingCountVac/Population)*100 as VacPercentage
FROM PopvsVac
ORDER by 2,3

-- Create Temp Table

Create Table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCountVac numeric
)

Insert Into #PercentPopVaccinated
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVac
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingCountVac/Population)*100 as PercentRollingVac
FROM #PercentPopVaccinated

-- Creating view to store data for later visualizations

Create View PercentPopulationVac as
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as INT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVac
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVac
