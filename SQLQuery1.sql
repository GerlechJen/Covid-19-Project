--Data Exploration 
--Skills utilized: Converting Data Types, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views 


--Checking correct importation of CovidVaccinations file
SELECT *
FROM ['Covid Vaccinations$']
ORDER BY 3,4

--Checking correct importation of CovidDeaths file
SELECT *
FROM ['Covid Deaths$']
ORDER BY 3,4


SELECT *
FROM ['Covid Deaths$']
WHERE continent is not null 
ORDER BY 3,4

-- Selecting specific data to work with 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM ['Covid Deaths$']
WHERE continent is not null 
ORDER BY 1,2


-- Total Cases vs Total Deaths to see likelihood of dying if you contract covid in your country on specific dates

SELECT Location, date, total_cases,total_deaths, (CAST(total_deaths AS int)/total_cases)*100 AS DeathPercentage
FROM ['Covid Deaths$']
WHERE continent is not null 
ORDER BY 1,5 DESC

-- Total Cases vs Total Deaths to see likelihood of dying if you contract covid in your country

SELECT Location,SUM(CAST(total_deaths AS int)) Deaths,  SUM(total_cases) Cases, (SUM(CAST(total_deaths AS int))/SUM(total_cases))*100 AS DeathPercentage
FROM ['Covid Deaths$']
WHERE continent is not null 
GROUP BY Location
ORDER BY 4 DESC


-- Total Cases vs Total Deaths in Canada by date

SELECT Location, date, total_cases,total_deaths, (CAST(total_deaths AS int)/total_cases)*100 AS DeathPercentage
FROM ['Covid Deaths$']
WHERE location = 'Canada' and continent is not null 
ORDER BY 2

--Overall Total Cases vs Total Deaths in Canada
SELECT Location, SUM(total_cases) Cases,SUM(CAST(total_deaths AS int)) Deaths, (SUM(CAST(total_deaths AS int))/SUM(total_cases))*100 AS DeathPercentage
FROM ['Covid Deaths$']
WHERE location = 'Canada' and continent is not null 
GROUP BY Location


-- Total Cases vs Population.Shows what percentage of population is infected with Covid per Day

SELECT Location, date, Population, total_cases, (total_cases /population)*100 AS PercentPopulationInfected
FROM ['Covid Deaths$']
ORDER BY 1,2

-- Total Cases vs Population.Shows what percentage of population is infected with Covid per Country

SELECT Location, AVG(Population) Population, SUM(total_cases) "Total Cases", (SUM(total_cases) /SUM(population))*100 AS PercentPopulationInfected
FROM ['Covid Deaths$']
GROUP BY Location
ORDER BY 4 DESC



-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM ['Covid Deaths$']
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


--Canada's highest infection rate 

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM ['Covid Deaths$']
WHERE location = 'Canada'
GROUP BY Location, Population



-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM ['Covid Deaths$']
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Contintents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
From ['Covid Deaths$']
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Different categories of locations with the highest death count per population


SELECT Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
From ['Covid Deaths$']
WHERE continent is null 
GROUP BY location
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

--Overall records

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM ['Covid Deaths$']
WHERE continent is not null 
ORDER BY 1,2

--Records by date

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM ['Covid Deaths$']
WHERE continent is not null 
GROUP BY Date
ORDER BY 1,2


--Joining the two tables
SELECT * 
FROM ['Covid Deaths$'] dea
JOIN ['Covid Vaccinations$'] vac
ON dea.location = vac.location
and dea.date = vac.date 

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ['Covid Deaths$'] dea
JOIN ['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From ['Covid Deaths$'] dea
Join ['Covid Vaccinations$'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 "Vaccination Rate"
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated bigint
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM ['Covid Deaths$'] dea
JOIN ['Covid Vaccinations$'] vac
ON dea.location = vac.location
WHERE dea.continent IS NOT NULL
AND dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100 AS "Vaccination Rate"
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ['Covid Deaths$'] dea
JOIN ['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null 



