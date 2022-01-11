/* 
Ahoj Williame,
přikládám Ti požadovanou výslednou tabulku pro Tvoje potřeby t_jiri_zachar_projekt_SQL_final. Pokud Ti nebudou vyhovovat některé údaje, tak mě prosím kontaktuj a 
data upravíme dle potřeby. V přiloženém skriptu vidíš můj postup i s poznámkami k jednotlivým krokům. Vše jsem připravil, tak aby se finální tabulka vytvořila přes ALT+X.
Do finální tabulky jsem zakomponoval i data pokud v některém řádku a sloupci chyběly zdrojové údaje. Např. koeficient gini má dosti málo položek v některých letech a
u některých států.
Obdobné údaje jsou o počasí, kde lze pracovat pouze se 34 státy apod. Přišlo mi, ale škoda, že bych udělal pouze agregaci na finální tabulku z dat, kde jsou všechny údaje.

Jirka Zachař
 
SQL
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
	t_jiri_zachar_confirmed_tests_population_1M tjzctpm 
;


-- tvorba tabulky pro zakódování ročního období, přestupný rok s chybou v letech 2100, 2200, což není důležité pro tento projekt apod.
CREATE OR REPLACE TABLE t_jiri_zachar_confirmed_weekend_leap AS
SELECT 
*,
YEAR (date),
CASE WHEN YEAR (date) MOD 4 = 0 THEN 1
ELSE 0 
END AS leap
FROM 
t_jiri_zachar_confirmed_weekend 
;

-- doplnění země, kde se nachází severní polokoule, jižní nebo rovník
CREATE OR REPLACE TABLE 
t_jiri_zachar_n_s_hemisphere
SELECT country, north, south, iso3 ,
    CASE WHEN south > 0 THEN 'north'
        WHEN north < 0 THEN 'south'
        ELSE 'equator'
        END AS 'N_S_hemisphere'
FROM countries 
WHERE north IS NOT NULL 
    AND south IS NOT NULL
;

-- spojení tabulek pro přidání sloupce N_S_hemisphere
CREATE OR REPLACE TABLE 
t_jiri_zachar_confirmed_weekend_leap_n_s_hemisphere
SELECT 
tjzcwl.*,
tjznsh.N_S_hemisphere 
FROM 
t_jiri_zachar_confirmed_weekend_leap tjzcwl 
JOIN t_jiri_zachar_n_s_hemisphere tjznsh 
ON tjzcwl.iso3 = tjznsh.iso3 
;

/* doplnění sloupce roční období v rámci zjednodušení nepřepočítávám slunovrat na konkrétní rok
 jaro je od 21.3-20.6, léto 21.6-22.10, podzim 23.10-20.12, zima 21.12-20.3 na severní polokouli, na jižní to bude zrcadlově a rovník bude pouze léto
 neberu v potaz další roční období jako např. období monzunů, deště, sucha apod.
 0 - zima
 1 - jaro
 2 - léto
 3 - podzim
 20.3 - 79, 21.3. - 80, 20.6 - 172, 21.6 - 173, 22.10 - 296, 23.10 - 297, 20.12 - 355, 21.12 - 356*/

CREATE OR REPLACE TABLE 
t_jiri_zachar_confirmed_weekend_season
SELECT
*,
CASE WHEN N_S_hemisphere = 'north' AND leap = 1 AND dayofyear(date) < 81 THEN 0
 WHEN N_S_hemisphere = 'north' AND leap = 0 AND dayofyear(date) < 80 THEN 0
 WHEN N_S_hemisphere = 'south' AND leap = 1 AND dayofyear(date) < 81 THEN 2
 WHEN N_S_hemisphere = 'south' AND leap = 0 AND dayofyear(date) < 80 THEN 2
 WHEN N_S_hemisphere = 'north' AND leap = 1 AND dayofyear(date) >= 81 AND dayofyear(date) < 173 THEN 1
 WHEN N_S_hemisphere = 'north' AND leap = 0 AND dayofyear(date) >= 80 AND dayofyear(date) < 172 THEN 1
 WHEN N_S_hemisphere = 'south' AND leap = 1 AND dayofyear(date) >= 81 AND dayofyear(date) < 173 THEN 3
 WHEN N_S_hemisphere = 'south' AND leap = 0 AND dayofyear(date) >= 80 AND dayofyear(date) < 172 THEN 3
 WHEN N_S_hemisphere = 'north' AND leap = 1 AND dayofyear(date) >= 173 AND dayofyear(date) < 297 THEN 2
 WHEN N_S_hemisphere = 'north' AND leap = 0 AND dayofyear(date) >= 172 AND dayofyear(date) < 296 THEN 2
 WHEN N_S_hemisphere = 'south' AND leap = 1 AND dayofyear(date) >= 173 AND dayofyear(date) < 297 THEN 0
 WHEN N_S_hemisphere = 'south' AND leap = 0 AND dayofyear(date) >= 172 AND dayofyear(date) < 296 THEN 0
 WHEN N_S_hemisphere = 'north' AND leap = 1 AND dayofyear(date) >= 297 AND dayofyear(date) < 356 THEN 3
 WHEN N_S_hemisphere = 'north' AND leap = 0 AND dayofyear(date) >= 296 AND dayofyear(date) < 355 THEN 3
 WHEN N_S_hemisphere = 'south' AND leap = 1 AND dayofyear(date) >= 297 AND dayofyear(date) < 356 THEN 1
 WHEN N_S_hemisphere = 'south' AND leap = 0 AND dayofyear(date) >= 296 AND dayofyear(date) < 355 THEN 1
 WHEN N_S_hemisphere = 'north' AND leap = 1 AND dayofyear(date) >= 356 THEN 0
 WHEN N_S_hemisphere = 'north' AND leap = 0 AND dayofyear(date) >= 355 THEN 0
 WHEN N_S_hemisphere = 'south' AND leap = 1 AND dayofyear(date) >= 356 THEN 2
 WHEN N_S_hemisphere = 'south' AND leap = 0 AND dayofyear(date) >= 355 THEN 2
 WHEN N_S_hemisphere = 'equator' THEN 2
END AS season
FROM 
t_jiri_zachar_confirmed_weekend_leap_n_s_hemisphere 
;

-- finální tabulka s údaji o časových proměnných
CREATE OR REPLACE TABLE 
t_jiri_zachar_time_variable_final
SELECT 
date,
country ,
population ,
confirmed ,
`confirmed/1M pop` ,
tests_performed ,
`test/1M pop` ,
weekend ,
season ,
iso3 
FROM 
t_jiri_zachar_confirmed_weekend_season tjzcws 
;

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
CREATE OR REPLACE TABLE t_jiri_zachar_country_economics_final
SELECT 
tjzvcr.*,
tjzle.life_exp_diff_1965_2015 
FROM 
t_jiri_zachar_variable_country_religion tjzvcr 
LEFT JOIN t_jiri_zachar_life_expectancy tjzle 
ON tjzvcr.country = tjzle.country 
WHERE tjzvcr.country IS NOT NULL 
;

/* v tabulce weather je pouze 34 měst, zadání na výpočet průměrné denní teploty je diskutabilní, protože meteorologická metodika
definuje výpočet takto: Odečet teploty vzduchu se provádí každý den v klimatologických termínech, tedy vždy v 7:00, 14:00 a 21:00 SEČ
 (resp. 8:00, 15:00 a 22:00 SELČ). Naměřená teplota se uvádí v Celsiových stupních (°C). 
 Z naměřených hodnot se pak váženým průměrem (7 + 14 + 2*21)/4 určuje průměrná denní teplota. Toto platí pro ČR, každý kontinent a stát
 to má trochu jinak. Pro zjednodušení tohoto projektu zde denní teploty budu uvažovat 9,12,15 a 18hod v příslušném dni*/

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
CAST (trim(TRAILING 'mm'FROM rain)AS decimal (3,1)) AS 'conversion/rain'
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

-- výpočet průměrné teploty s tím, že beru v potaz hodnoty v 9, 12, 15 a 18hod a vypočítám z nich průměr
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

-- joinutí tabulky s průměrnou denní teplotou a výběrem z weather
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_daily_conversion
SELECT
tjzwc.date,
tjzwc.city,
tjzwc.`time` ,
tjzwc.`conversion/rain` ,
tjzwc.`conversion/gust` ,
tjzwdat.`avg/temp` 
FROM 
t_jiri_zachar_weather_conversion tjzwc 
JOIN 
t_jiri_zachar_weather_daily_avg_temp tjzwdat 
ON tjzwc.`date` = tjzwdat.`date` 
AND tjzwc.city = tjzwdat.city 
;

-- počet hodin v daném dni, kdy byly srážky nenulové
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_rainwithoutnull
SELECT 
*,
CASE WHEN `conversion/rain` > 0 THEN 1
ELSE 0 END AS 'daily'
FROM 
t_jiri_zachar_weather_daily_conversion
;

-- naplnění tabulky s přepočtem celkových hodin za den, kdy jsou srážky nenulové
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_rainwithoutnull_final
SELECT
*,
sum(daily)*3 AS 'day/rain'
FROM
t_jiri_zachar_weather_rainwithoutnull
GROUP BY date, city
;

-- joinutí tabulky s průměrnou denní teplotou a tabulkou kdy jsou srážky nenulové
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_daily_conversion_rain
SELECT
tjzwc.date,
tjzwc.city,
tjzwc.`time` ,
tjzwc.`conversion/gust` ,
tjzwrf.`avg/temp` ,
tjzwrf.`day/rain` 
FROM 
t_jiri_zachar_weather_conversion tjzwc 
JOIN 
t_jiri_zachar_weather_rainwithoutnull_final tjzwrf 
ON tjzwc.`date` = tjzwrf.`date` 
AND tjzwc.city = tjzwrf.city 
;

-- maximální síla větru během dne
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_daily_conversion_rain_gust
SELECT 
*,
max(`conversion/gust`) AS 'day/gust'
FROM 
t_jiri_zachar_weather_daily_conversion_rain
GROUP BY date, city
;

-- joinutí tabulky s průměrnou denní teplotou, počet hodin kdy byly srážky nenulové a tabulkou s maximální silou větru
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_temp_rain_gust
SELECT
tjzwc.date,
tjzwc.city,
tjzwc.`time` ,
tjzwdcrg.`avg/temp` ,
tjzwdcrg.`day/rain` ,
tjzwdcrg.`day/gust` 
FROM 
t_jiri_zachar_weather_conversion tjzwc 
JOIN 
t_jiri_zachar_weather_daily_conversion_rain_gust tjzwdcrg 
ON tjzwc.`date` = tjzwdcrg.`date` 
AND tjzwc.city = tjzwdcrg.city 
;

/* navázání země a zkratky iso na tabulku, kde jsou vypočítány hodnoty z weather přes tabulku cities z důvodu toho, že města mají rozdílné názvy
např. Praha vs Prague */
CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_semifinal
SELECT 
tjzwtrg.*,
c.country ,
c.iso3 
FROM 
t_jiri_zachar_weather_temp_rain_gust tjzwtrg 
JOIN cities c 
ON tjzwtrg.city = c.city
AND c.capital = 'primary'
ORDER BY tjzwtrg.`date` 
;

CREATE OR REPLACE TABLE 
t_jiri_zachar_weather_final 
SELECT 
*
FROM 
t_jiri_zachar_weather_semifinal tjzws 
WHERE date > '2020-01-22'
GROUP BY date , city
;

-- spojení tabulek časových a ekonomických proměnných datum od 2020-01-23-2021-05-23
CREATE OR REPLACE TABLE 
t_jiri_zachar_projekt_SQL_semifinal
SELECT 
tjztvf.*,
tjzcef.`population density` ,
tjzcef.GDP ,
tjzcef.gini ,
tjzcef.mortaliy_under5 ,
tjzcef.median_age_2018 ,
tjzcef.religion ,
tjzcef.religion_share_2020 ,
tjzcef.life_exp_diff_1965_2015 
FROM 
t_jiri_zachar_time_variable_final tjztvf 
JOIN t_jiri_zachar_country_economics_final tjzcef 
ON tjztvf.iso3 = tjzcef.iso3 
;

-- vytvoření předfinální tabulky neseřazené
CREATE OR REPLACE TABLE 
t_jiri_zachar_projekt_SQL_prefinal
SELECT 
tjzpss.*,
tjzwf.`avg/temp` ,
tjzwf.`day/rain` ,
tjzwf.`day/gust` 
FROM 
t_jiri_zachar_projekt_SQL_semifinal tjzpss 
LEFT JOIN t_jiri_zachar_weather_final tjzwf 
ON tjzpss.date = tjzwf.`date` 
AND tjzpss.iso3 = tjzwf.iso3 
;

-- seřazení finální tabulky 
CREATE OR REPLACE TABLE 
t_jiri_zachar_projekt_SQL_final
SELECT 
*
FROM 
t_jiri_zachar_projekt_SQL_prefinal
ORDER BY date, country
;

/*SELECT 
*
FROM 
t_jiri_zachar_projekt_SQL_final
*/

-- vyčištění pomocných tabulek
DROP TABLE
t_jiri_zachar_confirmed ,
t_jiri_zachar_confirmed_iso ,
t_jiri_zachar_confirmed_tests ,
t_jiri_zachar_confirmed_tests_population ,
t_jiri_zachar_confirmed_tests_population_1M ,
t_jiri_zachar_confirmed_weekend ,
t_jiri_zachar_confirmed_weekend_leap ,
t_jiri_zachar_confirmed_weekend_leap_n_s_hemisphere ,
t_jiri_zachar_confirmed_weekend_season ,
t_jiri_zachar_country_economics_final ,
t_jiri_zachar_life_expectancy ,
t_jiri_zachar_n_s_hemisphere ,
t_jiri_zachar_projekt_SQL_prefinal ,
t_jiri_zachar_projekt_SQL_semifinal ,
t_jiri_zachar_religion ,
t_jiri_zachar_time_variable_final ,
t_jiri_zachar_variable_country ,
t_jiri_zachar_variable_country_religion ,
t_jiri_zachar_weather ,
t_jiri_zachar_weather_conversion ,
t_jiri_zachar_weather_daily ,
t_jiri_zachar_weather_daily_avg_temp ,
t_jiri_zachar_weather_daily_conversion ,
t_jiri_zachar_weather_daily_conversion_rain ,
t_jiri_zachar_weather_daily_conversion_rain_gust ,
t_jiri_zachar_weather_final ,
t_jiri_zachar_weather_rainwithoutnull ,
t_jiri_zachar_weather_rainwithoutnull_final ,
t_jiri_zachar_weather_semifinal ,
t_jiri_zachar_weather_temp_rain_gust 
;
