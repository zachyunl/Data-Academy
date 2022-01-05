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

-- vytvoření základní tabulky pouze potvrzených případů - datum, země, potvrzené případy
CREATE TABLE t_jiri_zachar_confirmed AS 
SELECT 
   date,
   country,
   confirmed
   FROM covid19_basic_differences cbd 
WHERE confirmed IS NOT NULL 
;

-- vytvoření tabulky s potvrzenými případy a provedenými testy
CREATE TABLE t_jiri_zachar_confirmed_tests
SELECT 
tjzc.date,
tjzc.country,
tjzc.confirmed,
ct.tests_performed
FROM 
t_jiri_zachar_confirmed tjzc 
LEFT JOIN covid19_tests ct 
ON tjzc.date = ct.date
AND tjzc.country = ct.country 
;

-- vytvoření tabulky s potvrzenými případy a provedenými testy a populací
CREATE TABLE t_jiri_zachar_confirmed_tests_population
SELECT 
tjzct.*,
c.population 
FROM t_jiri_zachar_confirmed_tests tjzct 
LEFT JOIN countries c 
ON tjzct.country = c.country 
;

-- doplnění do tabulky potvrzené případy, testy v přepočtu na populaci a 1M obyvatel, data jsou za roky 2020 a 2021
SELECT 
*,
(confirmed / population) * 1000000 AS 'confirmed/1M pop' ,
(tests_performed / population) * 1000000 AS 'test/1M pop' 
FROM 
t_jiri_zachar_confirmed_tests_population
GROUP BY country 
;
-- doplnění sloupce weekend dle České republiky sobota a neděle je víkend, neberou se v potaz anomálie z jiných částí světa, kdy je víkend např. čtvrtek a pátek
CREATE TABLE t_jiri_zachar_confirmed_weekend AS
SELECT
*,
CASE WHEN weekday(date) > 4 THEN 1
ELSE 0 
END AS weekend 
FROM  
t_jiri_zachar_confirmed tjzc 
;

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

-- propojení tabulek země a ekonomika, výpočet hustoty zalidnění dle jednotlivých let bere se v potaz pouze změna počtu obyvatel, nikoliv velikost území
-- HDP na obyvatele, GINI koeficient, dětská úmrtnost, medián věku obyvatel v roce 2018
SELECT 
c.country ,
c.population ,
round ((e.population / c.surface_area),3) AS 'population density',
e.GDP,
e.gini ,
e.mortaliy_under5 ,
c.median_age_2018 
FROM
countries c 
LEFT JOIN economies e 
ON c.country = e.country 
;

-- tabulka náboženství - nesmyslná data, která vyjadřují roky v budoucnu. Jako joke jsem si prohlédl Českou republiku a ateismus stále vítězí...
-- nakonec použiji jako základ cvičení, které jsme dělali, nemá smysl vymýšlet kolo...
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

-- tabulka rozdíl mezi očekávanou dobou dožití v roce 1965 a 2015
SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_diff
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

-- tabulka pro průměrnou denní teplotu
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

SELECT 
c.country, c.date, c.confirmed , lt.iso3 , c2.capital_city #, w.max_temp
FROM covid19_basic as c
JOIN lookup_table lt 
    on c.country = lt.country 
    and c.country = 'Czechia'
    and month(c.date) = 10
    JOIN countries c2
    on lt.iso3 = c2.iso3
JOIN ( SELECT w.city , w.date , max(w.temp) as max_temp
        FROM weather w 
        ) w
    on c2.capital_city = w.city 
    and c.date = w.date
ORDER BY c.date desc
;

SELECT 
*
FROM 
covid19_basic cb 
WHERE country = 'czechia'
