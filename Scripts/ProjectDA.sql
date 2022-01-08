/*SQL
CVIČENÍ PRO DATOVOU AKADEMII​/PROJEKTY​/SQL
Zadání: Od Vašeho kolegy statistika jste obdrželi následující email:

##########

Dobrý den,

snažím se určit faktory, které ovlivňují rychlost šíření koronaviru na úrovni jednotlivých států. Chtěl bych Vás, coby datového analytika, požádat o pomoc s přípravou dat, která potom budu statisticky zpracovávat. Prosím Vás o dodání dat podle požadavků sepsaných níže.

Výsledná data budou panelová, klíče budou stát (country) a den (date). Budu vyhodnocovat model, který bude vysvětlovat denní nárůsty nakažených v jednotlivých zemích. Samotné počty nakažených mi nicméně nejsou nic platné - je potřeba vzít v úvahu také počty provedených testů a počet obyvatel daného státu. Z těchto tří proměnných je potom možné vytvořit vhodnou vysvětlovanou proměnnou. Denní počty nakažených chci vysvětlovat pomocí proměnných několika typů. Každý sloupec v tabulce bude představovat jednu proměnnou. Chceme získat následující sloupce:

Časové proměnné
binární proměnná pro víkend / pracovní den
roční období daného dne (zakódujte prosím jako 0 až 3)
Proměnné specifické pro daný stát
hustota zalidnění - ve státech s vyšší hustotou zalidnění se nákaza může šířit rychleji
HDP na obyvatele - použijeme jako indikátor ekonomické vyspělosti státu
GINI koeficient - má majetková nerovnost vliv na šíření koronaviru?
dětská úmrtnost - použijeme jako indikátor kvality zdravotnictví
medián věku obyvatel v roce 2018 - státy se starším obyvatelstvem mohou být postiženy více
podíly jednotlivých náboženství - použijeme jako proxy proměnnou pro kulturní specifika. Pro každé náboženství v daném státě bych chtěl procentní podíl jeho příslušníků na celkovém obyvatelstvu
rozdíl mezi očekávanou dobou dožití v roce 1965 a v roce 2015 - státy, ve kterých proběhl rychlý rozvoj mohou reagovat jinak než země, které jsou vyspělé už delší dobu
Počasí (ovlivňuje chování lidí a také schopnost šíření viru)
průměrná denní (nikoli noční!) teplota
počet hodin v daném dni, kdy byly srážky nenulové
maximální síla větru v nárazech během dne
Napadají Vás ještě nějaké další proměnné, které bychom mohli použít? Pokud vím, měl(a) byste si vystačit s daty z následujících tabulek: countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_testing, weather, lookup_table.

V případě nejasností se mě určitě zeptejte.

S pozdravem, Student (a.k.a. William Gosset)

###############################

Výstup: Pomozte Vašemu kolegovi s daným úkolem. Výstupem by měla být tabulka na databázi, ze které se požadovaná data dají získat jedním selectem. Tabulku pojmenujte t_{jméno}_{příjmení}_projekt_SQL_final. Na svém GitHub účtu vytvořte repozitář (může být soukromý), kam uložíte všechny informace k projektu - hlavně SQL skript generující výslednou tabulku, popis mezivýsledků, informace o výstupních datech (například kde chybí hodnoty apod.). Případné pomocné tabulky neukládejte na DB jako view! Vždy vytvořte novou tabulku (z důvodu anonymity).
*/

/*Řešení bude přes dočasné výpočetní tabulky až po naplnění finální dle zadání. Přes Alt+X se postupně vykoná kompletní řešení
 *
 */


DROP TABLE
t_jiri_zachar_confirmed ,
t_jiri_zachar_confirmed_weekend 
t_jiri_zachar_confirmed_tests
t_jiri_zachar_confirmed_tests_population
;

-- vytvoření základní tabulky pouze potvrzených případů - datum, země, potvrzené případy, iso3 z důvodu joinování na další tabulky
CREATE OR REPLACE
TABLE t_jiri_zachar_confirmed AS 
SELECT
	cbd.date,
	cbd.country,
	cbd.confirmed
FROM
	covid19_basic_differences cbd
WHERE confirmed IS NOT NULL 
;
   
/* joinutí k tabulce confirmed ISO3 z důvodu navazování dalších tabulek. Bohužel jsou v některých tabulkách rozdílné názvy zemí a nejbezečnější to je 
 joinovat přes ISO. */
CREATE OR REPLACE 
TABLE t_jiri_zachar_confirmed_iso AS
SELECT
	tjzc.*,
	lt.iso3
FROM
	t_jiri_zachar_confirmed tjzc
JOIN lookup_table lt
ON
	tjzc.country = lt.country 
WHERE lt.province IS NULL 
;

-- vytvoření tabulky s potvrzenými případy a provedenými testy
CREATE OR REPLACE
TABLE t_jiri_zachar_confirmed_tests
SELECT
	tjzci.date,
	tjzci.country,
	tjzci.confirmed,
	ct.tests_performed,
	tjzci.iso3
FROM
	t_jiri_zachar_confirmed_iso tjzci
LEFT JOIN covid19_tests ct 
ON
	tjzci.date = ct.date
	AND tjzci.iso3 = ct.ISO 
;

-- vytvoření tabulky s potvrzenými případy a provedenými testy a populací
CREATE OR REPLACE
TABLE t_jiri_zachar_confirmed_tests_population
SELECT
	tjzct.*,
	c.population
FROM
	t_jiri_zachar_confirmed_tests tjzct
LEFT JOIN countries c 
ON
	tjzct.iso3 = c.iso3 
;

-- doplnění do tabulky potvrzené případy, testy v přepočtu na populaci a 1M obyvatel, data jsou za roky 2020 a 2021
CREATE OR REPLACE
TABLE t_jiri_zachar_confirmed_tests_population_1M
SELECT
	*,
	(confirmed / population) * 1000000 AS 'confirmed/1M pop' ,
	(tests_performed / population) * 1000000 AS 'test/1M pop'
FROM
	t_jiri_zachar_confirmed_tests_population
;

-- doplnění sloupce weekend dle České republiky sobota a neděle je víkend, neberou se v potaz anomálie z jiných částí světa, kdy je víkend např. čtvrtek a pátek
CREATE OR REPLACE
TABLE t_jiri_zachar_confirmed_weekend AS
SELECT
	*,
	CASE
		WHEN weekday(date) > 4 THEN 1
		ELSE 0
	END AS weekend
FROM
	t_jiri_zachar_confirmed_tests_population_1m tjzctpm 
;

SELECT 
*
FROM 
t_jiri_zachar_confirmed_weekend tjzcw 
ORDER BY `date` 


-- přestupný rok s chybou v letech 2100, 2200 apod.
CREATE TABLE t_jiri_zachar_country_leap AS
SELECT 
*,
YEAR (date),
CASE WHEN YEAR (date) MOD 4 = 0 THEN 1
ELSE 0 
END AS leap
FROM 
t_jiri_zachar_country tjzc 
GROUP BY country , date

-- doplnění sloupce roční období v rámci zjednodušení neberu v potaz rozdíl jižní a severní polokouli a dále nepřepočítávám slunovrat na konkrétní rok
-- jaro je od 21.3-20.6, léto 21.6-22.10, podzim 23.10-20.12, zima 21.12-20.3
-- 20.3 - 79, 21.3. - 80, 20.6 - 172, 21.6 - 173, 22.10 - 296, 23.10 - 297, 20.12 - 355, 21.12 - 356
SELECT
*
/*CASE WHEN leap = 0 and dayofyear(date) < 81 THEN 0
CASE WHEN leap = 1 AND dayofyear(date) < 80 THEN 0
CASE WHEN leap = 0 AND dayofyear(date) > 80  AND dayofyear(date) < 172 THEN 1
CASE WHEN leap = 1 AND dayofyear(date) > 81  AND dayofyear(date) < 173 THEN 1
END AS seasons*/ 
FROM 
t_jiri_zachar_country_leap 
GROUP BY country , date

/* propojení tabulek země a ekonomika, výpočet hustoty zalidnění dle jednotlivých let bere se v potaz pouze změna počtu obyvatel, nikoliv velikost území
 HDP na obyvatele, GINI koeficient, dětská úmrtnost, medián věku obyvatel v roce 2018, iso3 - vybral jsem rok 2019, protože je problematické 
z důvodu koeficientu gini zvolit něco vhodného za rok. Nehledě na další koeficient median_age_2018, kdy je určitě konzistentní vybírat ekonomická data
až po tomto roce */

CREATE OR REPLACE TABLE t_jiri_zachar_variable_country AS
SELECT
	c.country ,
	c.population ,
	round ((e.population / c.surface_area),
	3) AS 'population density',
	e.GDP,
	e.gini ,
	e.mortaliy_under5 ,
	c.median_age_2018 ,
	c.iso3 
	FROM
	countries c
LEFT JOIN economies e 
ON
	c.country = e.country
WHERE e.`year` = 2019
	;

SELECT 
*
FROM 
t_jiri_zachar_variable_country tjzvc 


/* tabulka náboženství - nesmyslná data, která vyjadřují roky v budoucnu. Jako joke jsem si prohlédl Českou republiku a ateismus stále vítězí...
 nakonec použiji jako základ cvičení, které jsme dělali, nemá smysl vymýšlet kolo...czech republic */
CREATE OR REPLACE TABLE t_jiri_zachar_religion
SELECT r.country , r.religion , 
    round( r.population / r2.total_population_2020 * 100, 2 ) as religion_share_2020
FROM religions r 
JOIN (
        SELECT r.country , r.year,  sum(r.population) as total_population_2020
        FROM religions r 
        WHERE r.year = 2020 and r.country != 'All Countries'
        GROUP BY r.country
    ) r2
    ON r.country = r2.country
    AND r.year = r2.year
    AND r.population > 0
;

-- náboženství a ekonomiky přes joiny
CREATE OR REPLACE TABLE t_jiri_zachar_variable_country_religion
SELECT 
tjzvc.*,
tjzr.religion ,
tjzr.religion_share_2020 
FROM 
t_jiri_zachar_religion tjzr 
LEFT JOIN t_jiri_zachar_variable_country tjzvc 
ON tjzr.country = tjzvc.country 
;

-- tabulka rozdíl mezi očekávanou dobou dožití v roce 1965 a 2015 - czech republic
CREATE OR REPLACE TABLE t_jiri_zachar_life_expectancy
SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_diff_1965_2015
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country
;

-- joinutí life_expectancy na zbytek ekonomických ukazatelů
CREATE OR REPLACE TABLE t_jiri_zachar_variable_country_religion_life_expectancy
SELECT 
tjzvcr.*,
tjzle.life_exp_diff_1965_2015 
FROM 
t_jiri_zachar_variable_country_religion tjzvcr 
LEFT JOIN t_jiri_zachar_life_expectancy tjzle 
ON tjzvcr.country = tjzle.country 
WHERE tjzvcr.country IS NOT NULL 
;

SELECT 
*
FROM
t_jiri_zachar_variable_country_religion_life_expectancy tjzvcrle 
GROUP BY country 

-- tabulka pro průměrnou denní teplotu, navázat přes tabulku cities (Prague)
SELECT 
c.country, c.date, c.confirmed , lt.iso3 , c2.capital_city , w.max_temp
FROM covid19_basic as c
JOIN lookup_table lt 
    on c.country = lt.country 
    and c.country = 'France'
    and month(c.date) = 10
    JOIN countries c2
    on lt.iso3 = c2.iso3
JOIN ( SELECT w.city , w.date , max(w.temp) as max_temp
        FROM weather w 
        GROUP BY w.city, w.date) w
    on c2.capital_city = w.city 
    and c.date = w.date
ORDER BY c.date desc
;

/* v tabulce weather je pouze 34 měst, zadání na výpočet průměrné denní teploty je diskutabilní, protože meteorologická metodika
definuje výpočet takto: Odečet teploty vzduchu se provádí každý den v klimatologických termínech, tedy vždy v 7:00, 14:00 a 21:00 SEČ
 (resp. 8:00, 15:00 a 22:00 SELČ). Naměřená teplota se uvádí v Celsiových stupních (°C). 
 Z naměřených hodnot se pak váženým průměrem (7 + 14 + 2*21)/4 určuje průměrná denní teplota. Toto platí pro ČR, každý kontinent a stát
 to má trochu jinak. Pro zjednodušení zde denní teploty budu uvažovat 9,12,15 a 18hod v příslušném dni*/

-- naplnění základní tabulky z weather 
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather
SELECT 
`date` ,
city,
time,
temp,
gust,
rain
FROM 
weather w 
WHERE city IS NOT NULL 
; 

-- konverze jednotek na integer a decimal z důvodu dalších počtů, teploty deště a nárazového větru
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_conversion
SELECT 
*,
CAST (trim(TRAILING '°c'FROM temp) AS integer) AS 'conversion/temp',
CAST (trim(TRAILING 'km/h'FROM gust) AS integer) AS 'conversion/gust',
CAST (trim(TRAILING 'mm'FROM rain)AS decimal(10,1)) AS 'conversion/rain'
FROM 
t_jiri_zachar_weather tjzw 
;

-- tabulka pro průměrnou denní teplotu
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_daily
SELECT
*,
CASE WHEN time = '09:00' THEN 1
WHEN time = '12:00' THEN 1
WHEN time = '15:00' THEN 1
WHEN time = '18:00' THEN 1
ELSE 0
END AS daily
FROM 
t_jiri_zachar_weather_conversion
;


-- výpočet průměrné teploty
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_daily_avg_temp
SELECT
*,
sum(`conversion/temp`) /4 AS 'avg/temp'
FROM
t_jiri_zachar_weather_daily tjzwd 
WHERE daily = 1
GROUP BY date , city 
;


SELECT
*
FROM 
t_jiri_zachar_weather_conversion tjzwc 
JOIN 
t_jiri_zachar_weather_daily_avg_temp tjzwdat 
ON tjzwc.`date` = tjzwdat.`date` 
AND tjzwc.city = tjzwdat.city 

-- počet hodin v daném dni, kdy byly srážky nenulové
SELECT 
*,
CASE WHEN rain > 0.0 THEN 1
ELSE 0 END AS 'rain/ratio'
FROM 

-- grupování dle datumu
SELECT
date (date),
city,
`avg/temp` 
FROM
t_jiri_zachar_weather_daily_avg_temp tjzwdat 
;
