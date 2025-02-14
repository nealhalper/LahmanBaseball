--1
SELECT MIN(yearid) AS first_year,
		MAX(yearid) AS last_year
FROM teams;

--2
SELECT CONCAT(namefirst, ' ' ,namelast) AS full_name, height, name AS team, g_all AS total_games
FROM people INNER JOIN appearances USING(playerid)
			INNER JOIN teams USING (teamid, yearid)
WHERE height = (SELECT MIN(height) FROM people);

--3
SELECT namefirst, namelast, SUM(salary)::numeric::money AS total_salary
FROM people
INNER JOIN salaries
USING(playerid)
WHERE playerid IN (SELECT playerid
					FROM collegeplaying
					WHERE schoolid = (SELECT schoolid
										FROM schools
										WHERE schoolname = 'Vanderbilt University'))
GROUP BY namefirst, namelast
ORDER BY total_salary DESC NULLS LAST;

--4
SELECT SUM(CASE WHEN pos = 'OF' THEN po END) AS outfield_po,
	   SUM(CASE WHEN pos IN ('SS', '1B', '2B', '3B') THEN po END) AS infield_po,
	   SUM(CASE WHEN pos IN ('P', 'C') THEN po END) AS battery_po
FROM fielding 
WHERE yearid = 2016;

--5
WITH stat_totals_by_decade AS (SELECT CONCAT(LEFT(yearid::varchar, 3), '0''''s') AS decade,
									SUM(hr) AS total_homeruns, SUM(so) AS total_strikeouts, 
									SUM(g) AS total_games
								FROM teams
								WHERE yearid >= 1920
								GROUP BY decade
								ORDER BY decade ASC)
SELECT decade,
		ROUND(total_homeruns::numeric/(total_games::numeric/2),2) AS avg_homeruns_per_game,
		ROUND(total_strikeouts::numeric/(total_games::numeric/2),2) AS avg_strikeouts_per_game
FROM stat_totals_by_decade;

--6
WITH stat_totals_by_player AS (SELECT playerid, SUM(sb) AS total_stolen, 
									SUM(sb) + SUM(cs) AS attempts
								FROM batting
								WHERE yearid = 2016 
								GROUP BY playerid)
															   
SELECT playerid, namefirst, namelast, ROUND(MAX(success_rate_stealing),2)*100 AS success_rate
FROM (SELECT playerid, (total_stolen::numeric/attempts::numeric) AS success_rate_stealing, attempts
		FROM stat_totals_by_player)
INNER JOIN people
USING(playerid)
WHERE attempts >= 20 
GROUP BY playerid, namefirst, namelast
ORDER BY success_rate DESC
LIMIT 1;

--7
(SELECT yearid, name, w, wswin
	FROM (SELECT yearid, name, w, wswin
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1981)
WHERE wswin = 'Y'
ORDER BY w ASC
LIMIT 1)
UNION
(SELECT yearid, name, w, wswin
	FROM (SELECT yearid, name, w, wswin
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016)
WHERE wswin = 'N'
ORDER BY w DESC
LIMIT 1);


WITH max_wins AS (SELECT DISTINCT yearid, MAX(w)
						OVER (PARTITION BY yearid) AS top_wins
						FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
						ORDER BY yearid),
						
	top_wins_won_ws AS (SELECT yearid, name, w, wswin,
							CASE WHEN w = top_wins THEN top_wins
							ELSE NULL END AS top_wins_won_ws
						FROM max_wins INNER JOIN teams	USING(yearid)
						WHERE wswin = 'Y')

SELECT ROUND((COUNT(top_wins_won_ws)::numeric/COUNT(*)::numeric)*100,2) AS percent_wswins_with_top_season_wins
FROM top_wins_won_ws;

--8
(WITH average_attendance AS (SELECT *, attendance/games AS avg_attendance
								FROM homegames
							WHERE games >= 10 AND year = 2016)
SELECT park, team, avg_attendance, 'top 5' AS attendance_rank
FROM average_attendance
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(WITH average_attendance AS (SELECT *, attendance/games AS avg_attendance
								FROM homegames
							WHERE games >= 10 AND year = 2016)
SELECT park, team, avg_attendance, 'bottom 5' AS attendance_rank
FROM average_attendance
ORDER BY avg_attendance ASC
LIMIT 5);

		
--9
WITH nl_and_al_awards AS (SELECT DISTINCT playerid, nl.yearid AS NL_winyear, al.yearid AS AL_winyear, nl.lgid AS NL, al.lgid AS AL
							FROM awardsmanagers AS nl
							FULL OUTER JOIN awardsmanagers AS al
							USING(playerid)
							WHERE nl.lgid = 'NL' AND al.lgid = 'AL' AND nl.awardid LIKE 'TSN%' AND al.awardid LIKE 'TSN%'
							ORDER BY nl.yearid, al.yearid),
 clean_awards AS ((SELECT playerid, NL AS award_lgid, NL_winyear AS yearid
						FROM nl_and_al_awards)
						UNION
						(SELECT playerid, AL AS lgid, AL_winyear AS yearid
						FROM nl_and_al_awards)
						ORDER BY playerid)
SELECT DISTINCT playerid, award_lgid, namefirst, namelast, name
FROM clean_awards
INNER JOIN managers
USING(playerid, yearid)
LEFT JOIN teams
USING(teamid)
INNER JOIN people
USING(playerid)
ORDER BY playerid
				



