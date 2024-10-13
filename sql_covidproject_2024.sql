USE covidproject


Select *
From covidproject..coviddeaths
WHERE continent is not null
order by 3,4

--Select *
--From covidproject..covidvaccinations
--order by 3,4

--Kullanacağımız verileri seçelim
Select location, date , total_cases , new_cases , total_deaths , population
FROM covidproject..coviddeaths
WHERE continent is not null
order by 1,2



--Toplam vakalara karşı toplam ölümlere bakacağız (total cases vs total death)
--Enfekte olan insanların yüzdesini öğrenmek istiyoruz

Select location, date , total_cases, total_deaths , (total_deaths/total_cases)*100 as DeathPercentage
FROM covidproject..coviddeaths
WHERE location like '%states%'
and continent is not null
order by 1,2 

--zero bölünmez hata verir o sebeple null verileri ayarlayalım
--Bu sorgu, total_cases sıfır olduğunda NULLIF(total_cases, 0) ifadesi NULL döndürecek ve sıfıra bölme hatası yerine sonuç NULL olacaktır.
SELECT location, 
       date, 
       total_cases, 
       total_deaths, 
       (total_deaths / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM covidproject..coviddeaths
WHERE location like '%states%'
ORDER BY location, date;


--Toplam vakalara ve nüfusa bakalım
--Nüfusun yüzde kaçının covid olduğunu göstermesini istedik
SELECT location, 
       date, 
	   population, 
       total_cases, 
       (total_cases / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM covidproject..coviddeaths
--WHERE location like '%states%'
ORDER BY location, date;




--Hangi ülkeler nüfusa kıyasla en yüksek enfeksiyon oranına sahip?

SELECT location, 
	   population, 
      MAX( total_cases) as HighestInfectionCount, 
      Max((total_cases / NULLIF(population, 0))) * 100 AS PercentPopulationInfected
FROM covidproject..coviddeaths
--WHERE location like '%states%'
Group BY location,population
Order by PercentPopulationInfected DESC


--En yüksek ölüm sayısına sahip ülkeler
--Kıtalara göre ayıralım
SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covidproject..coviddeaths
--WHERE location like '%states%'
WHERE continent is  null
Group BY location
Order by TotalDeathCount DESC



--En yüksek ölüm sayısına sahip ülkeler

SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covidproject..coviddeaths
--WHERE location like '%states%'
WHERE continent is not null
Group BY location
Order by TotalDeathCount DESC


--yüksek ölüm sayısına sahip kıtaları görelim
SELECT continent, Max(cast(total_deaths as int)) as TotalDeathCount
FROM covidproject..coviddeaths
--WHERE location like '%states%'
WHERE continent is not null
Group BY continent
Order by TotalDeathCount DESC


--GLOBAL NUMBERS
SELECT 
--  date, 

    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM 
    covidproject..coviddeaths
WHERE 
    continent IS NOT NULL
	----GROUP BY  date
ORDER BY 
    1,2;


-- Toplam nüfusa göre aşılamaya bakalım (population vs vaccinations)
--Dünyada aşılanan toplam insan sayısı kaçtır?
SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
, SUM(convert(float,vac.new_vaccinations )) OVER (Partition by dea.location order by dea.location ,
dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM covidproject..coviddeaths dea
JOIN covidproject..covidvaccinations1 vac
 on dea.location = vac.location
 and dea.date = vac.date
 Where dea.continent is not null
 order by 2,3


 --USE CTE
 With PopvsVac  (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
 as
( SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
, SUM(convert(float,vac.new_vaccinations )) OVER (Partition by dea.location order by dea.location ,
dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM covidproject..coviddeaths dea
JOIN covidproject..covidvaccinations1 vac
 on dea.location = vac.location
 and dea.date = vac.date
 Where dea.continent is not null
 --order by 2,3
 )
 select * , (RollingPeopleVaccinated/population)*100 from
 PopvsVac



 --temp table(geçici tablo)
 --aşılanan nüfus yüzdesi
-- DROP TABLE if exists  #PercentPopulationVaccinated
 create table #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 RollingPeopleVaccinated numeric
 )

 insert into #PercentPopulationVaccinated
 SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
, SUM(convert(float,vac.new_vaccinations )) OVER (Partition by dea.location order by dea.location ,
dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM covidproject..coviddeaths dea
JOIN covidproject..covidvaccinations1 vac
 on dea.location = vac.location
 and dea.date = vac.date
 Where dea.continent is not null
 --order by 2,3

  select * , (RollingPeopleVaccinated/population)*100 from
 #PercentPopulationVaccinated


 --verileri depolamak için görselleştirme oluşturuyoruz.
 Create View PercentPopulationVaccinated as
 SELECT dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations
, SUM(convert(float,vac.new_vaccinations )) OVER (Partition by dea.location order by dea.location ,
dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM covidproject..coviddeaths dea
JOIN covidproject..covidvaccinations1 vac
 on dea.location = vac.location
 and dea.date = vac.date
 Where dea.continent is not null
 --order by 2,3

 select* from PercentPopulationVaccinated