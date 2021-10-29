-- Exploratory Analysis of OWID-COVID19 Data

-- Preprocessing was done on the .csv file to split case counts and vaccination rates into two tables, and saving .csv to .xlxs for import into SSMS.

-- Check Table

SELECT *
FROM Portfolio.dbo.CovidDeaths

-- Check Relevant Areas for Exploration
-- Order it by its code and continent for orderliness

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio.dbo.CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- What is the COVID Mortality Rate in different countries? 
-- (Dividing Total Cases by Total Deaths to see how many people have died from those who have had COVID.)
-- What is the likelihood of dying if you contract COVID in your country?

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE location like 'Canada'
ORDER by 1,2

-- When did the COVID Mortality Rate peak in Canada?
-- The end of May 2020, and the highest mortality rates were during summer 2020.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE location like 'Canada'
ORDER by COVIDMortalityRate DESC

-- Looking at Total Cases vs Population
-- I can divide each country's population with the number of total cases in each country to determine what percentage of population contracted COVID.

SELECT Location, date, total_cases, Population, (total_cases/population)*100 AS COVIDPercentage
FROM Portfolio.dbo.CovidDeaths
WHERE location like 'Canada'
ORDER BY 1,2

-- Looking at countries with the Highest Infection Rate compared to Population
-- I am filtering out the continents in the data, only interested in countries.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS COVIDPercentage
FROM Portfolio.dbo.CovidDeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY COVIDPercentage DESC

-- Looking at countries with the Highest Death Count compared to Population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT null
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Looking at countries with the Highest COVID Mortality Rate

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount, MAX(total_deaths/total_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT null
GROUP BY Location
ORDER BY COVIDMortalityRate DESC

-- Break it down by Continent

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount, MAX(total_deaths/total_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS null
GROUP BY Location
ORDER BY COVIDMortalityRate DESC

-- What about global numbers?
-- How many per day?

SELECT date, SUM(new_cases) AS CaseCount, SUM(CAST(new_deaths AS int)) AS DeathCount, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1,2

-- How many total?

SELECT SUM(new_cases) AS CaseCount, SUM(CAST(new_deaths AS int)) AS DeathCount, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS COVIDMortalityRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT null
ORDER BY 1,2

-- Now, I am joining the COVID Vaccination table created in preprocessing to explore further.

SELECT *
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

-- A rolling vaccination count

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

-- Population vs Vaccination
-- I want to get the MAX rolling vaccination count so I can find out the percentage of people vaccination in each location.

-- By Using CTE
-- If the number of columns in the table == the CTE, you get an error

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *, (RollingVaccinations/Population)*100 AS PopPercentVaccinated
FROM PopvsVac

-- By Using a Temp. Table

DROP Table if exists #PercentPopVaccinated
CREATE Table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)
INSERT INTO #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
SELECT *, (RollingVaccinations/Population)*100 AS PopPercentVaccinated
FROM #PercentPopVaccinated

-- By Creating a View
-- To store data for later visualizations

CREATE VIEW PercentPopVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Portfolio.dbo.CovidDeaths dea
JOIN Portfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

-- END.
