/* SQL Portfolio project - Olympics History Analysis 

There are 2 dataset files. The data contains 120 years of olympics history.
1- athletes : It has information about all the players participated in olympics.
2- athlete_events : It has information about all the events happened over the year.(athlete id refers to the id column in athlete table)

Import these datasets in any sql platform and solve below problems:

1. Which team has won the maximum gold medals over the years.
2. For each team print total silver medals and year in which they won maximum silver medal..output 3 columns
team,total_silver_medals, year_of_max_silver
3. Which player has won maximum gold medals  amongst the players which have won only gold medal (never won silver or bronze) 
over the years.
4. In each year which player has won maximum gold medal. Write a query to print year,player name 
and no of golds won in that year. In case of a tie print comma separated player names.
5. In which event and year India has won its first gold medal,first silver medal and first bronze medal
print 3 columns - medal, year, event.
6. Find players who won gold medal in summer and winter olympics both.
7. Find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
8. Find players who have won gold medals in consecutive 3 summer olympics in the same event. Consider only olympics 2000 onwards. 
Assume summer olympics happens every 4 year starting 2000. print player name and event name. */

--SQL Platform Used: SQL Server

--1. Which team has won the maximum gold medals over the years.

WITH cte1
AS (
	SELECT a.team
		,COUNT(1) AS no_of_gold_medals
	FROM athlete_events ae
	INNER JOIN athletes a ON ae.athlete_id = a.id
	WHERE ae.medal = 'Gold'
	GROUP BY a.team
	)
	,cte2
AS (
	SELECT *
		,DENSE_RANK() OVER (ORDER BY no_of_gold_medals DESC) AS drnk
	FROM cte1
	)
SELECT team
	,no_of_gold_medals
FROM cte2
WHERE drnk = 1;

--2. For each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

with cte1 as
(select a.team
, COUNT(1) over(partition by team) as total_silver_medals
, ae.year as year_of_winning_silver_medal
from athlete_events ae
inner join athletes a on ae.athlete_id = a.id
where ae.medal = 'Silver')
, cte2 as
(select *
, COUNT(1) over(partition by team, year_of_winning_silver_medal) as total_silver_medals_yearly
from cte1)
, cte3 as
(select *
, DENSE_RANK() over(partition by team order by total_silver_medals_yearly desc) as drnk
from cte2)
select team, total_silver_medals, MAX(year_of_winning_silver_medal) as year_of_max_silver
from cte3 
where drnk = 1
group by team, total_silver_medals
order by team, total_silver_medals;

--3. Which player has won maximum gold medals  amongst the players which have won only gold medal (never won silver or bronze) 
-- over the years.

with cte1 as
(select a.name
, sum(case when medal = 'Gold' then 1 else 0 end) as total_gold_medals
, sum(case when medal in ('Silver', 'Bronze') then 1 else 0 end) as total_silver_bronze_medals
from athlete_events ae
inner join athletes a on ae.athlete_id = a.id
group by a.name)
, cte2 as
(select *
, DENSE_RANK() over(order by total_gold_medals desc) as drnk
from cte1
where total_gold_medals >= 1 and total_silver_bronze_medals = 0)
select name, total_gold_medals, total_silver_bronze_medals
from cte2 where drnk = 1;

--4. In each year which player has won maximum gold medal. Write a query to print year,player name 
-- and no of golds won in that year. In case of a tie print comma separated player names.

WITH cte1
AS (
	SELECT a.name, ae.year, COUNT(1) AS no_of_gold_medals
	FROM athlete_events ae
	INNER JOIN athletes a ON ae.athlete_id = a.id
	WHERE ae.medal = 'Gold'
	GROUP BY a.name, ae.year
	)
	,cte2
AS (
	SELECT *
		,DENSE_RANK() OVER (PARTITION BY year ORDER BY no_of_gold_medals DESC) AS drnk
	FROM cte1
	)
SELECT year, STRING_AGG(name, ',') as player_name, no_of_gold_medals
FROM cte2
WHERE drnk = 1
GROUP BY year, no_of_gold_medals
ORDER BY year, no_of_gold_medals;

--5. In which event and year India has won its first gold medal,first silver medal and first bronze medal
-- print 3 columns - medal, year, event.

with cte1 as
(SELECT ae.medal, ae.year, ae.event
, DENSE_RANK() over(partition by ae.medal order by ae.year) as drnk
FROM athlete_events ae
INNER JOIN athletes a ON ae.athlete_id = a.id
where a.team = 'India' and medal <> 'NA')
select distinct * 
from cte1
where drnk = 1;

--6. Find players who won gold medal in summer and winter olympics both.

SELECT a.name
, SUM(case when ae.season = 'Summer' then 1 else 0 end) as total_summer_gold_medals
, SUM(case when ae.season = 'Winter' then 1 else 0 end) as total_winter_gold_medals
FROM athlete_events ae
INNER JOIN athletes a ON ae.athlete_id = a.id
where ae.medal = 'Gold'
group by a.name
having SUM(case when ae.season = 'Summer' then 1 else 0 end) >= 1 and
SUM(case when ae.season = 'Winter' then 1 else 0 end) >= 1;

--7. Find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

SELECT a.name, ae.year
FROM athlete_events ae
INNER JOIN athletes a ON ae.athlete_id = a.id
WHERE ae.medal IN (
		'Gold'
		,'Silver'
		,'Bronze'
		)
GROUP BY a.name, ae.year
HAVING COUNT(DISTINCT ae.medal) = 3;

--8. Find players who have won gold medals in consecutive 3 summer olympics in the same event. Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

with cte1 as
(SELECT a.name as player_name, ae.event
, LAG(ae.year, 1) over(partition by a.name, ae.event order by ae.year) as prev_year
, ae.year as current_year
, LEAD(ae.year, 1) over(partition by a.name, ae.event order by ae.year) as next_year
FROM athlete_events ae
INNER JOIN athletes a ON ae.athlete_id = a.id
where ae.medal = 'Gold' and ae.season = 'Summer' and ae.year >= '2000')
select * 
from cte1
where prev_year = current_year - 4 and next_year = current_year + 4;