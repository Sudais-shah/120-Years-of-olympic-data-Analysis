-- Database: olympic_history

 --TABLE CREATION ATHELETE_EVENTS
   CREATE TABLE athelete_events(
   ID	INT ,
   Name   VARCHAR(160),Sex VARCHAR(100),   Age VARCHAR(100),   Height VARCHAR(100),
   Weight VARCHAR(100),Team VARCHAR(140),  NOC VARCHAR(100),
   Games VARCHAR(140), Year VARCHAR(100),  Season VARCHAR(140),
   City VARCHAR(100),  Sport VARCHAR(140), Event VARCHAR(140), Medal VARCHAR(100) )

 --TABLE CREATION NOC_REGIONS
   CREATE TABLE noc_regions(
   noc VARCHAR(20),
   region VARCHAR(50),
   notes  VARCHAR(70)
   )

-- 1. Which year saw the highest and lowest no of countries participating in olympics?
    (SELECT games, COUNT(DISTINCT noc) AS no_of_nations
	FROM athlete_events
	GROUP BY games
    ORDER BY no_of_nations ASC
    LIMIT 1)
    UNION ALL
    (SELECT games, COUNT(DISTINCT noc) AS no_of_nations
    FROM athlete_events
    GROUP BY games
    ORDER BY no_of_nations DESC
    LIMIT 1);

 -- 2. Which nation has participated in all of the olympic games?
    WITH total_games AS (
    SELECT COUNT(DISTINCT games) AS total_game_count
    FROM athelete_events
    ),
    nation_participation AS (
    SELECT ae.noc, COUNT(DISTINCT ae.games) AS nation_game_count
    FROM athelete_events ae
    GROUP BY ae.noc
    )
	
  --3. Now we select nations where their participation matches the total number of games
    SELECT nr.region, np.nation_game_count
    FROM nation_participation np
    JOIN noc_regions nr ON np.noc = nr.noc
    JOIN total_games tg ON np.nation_game_count = tg.total_game_count

                  -- 2nd method
    SELECT nr.region, COUNT(DISTINCT ae.games) AS participation_count
    FROM athelete_events ae
    JOIN noc_regions nr ON ae.noc = nr.noc
    GROUP BY nr.region
    HAVING COUNT(DISTINCT ae.games) = (SELECT COUNT(DISTINCT games) FROM athelete_events)
    ORDER BY participation_count DESC;

  --4. Identify the sport which was played in all summer olympics.
     SELECT DISTINCT sport , season FROM athelete_events 
	 where season in(SELECT season from athelete_events where season like 'Summer')
	
  --5. Fetch the top 5 athletes who have won the most gold medals.
      with cte AS (
      SELECT id as id ,name as name,
	  DENSE_RANK() OVER (ORDER BY count(medal) DESC) AS RANK ,
	  count(medal) as total_medals FROM athelete_events 
	  WHERE medal like 'Gold'
      GROUP BY 1,2 
	  ORDER BY count(medal) DESC 
	  )
      SELECT * FROM cte  WHERE RANK in (1,2,3,4,5)

  -- 6. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
      with cte_all_medals AS (
      SELECT id as id ,name as name,
	  DENSE_RANK() OVER (ORDER BY count(medal) DESC) AS RANK ,
	  count(medal) as total_medals FROM athelete_events 
	  WHERE medal in('Gold','Silver','Bronze')
      GROUP BY 1,2 
	  ORDER BY count(medal) DESC 
	  )
     SELECT * FROM  cte_all_medals  WHERE RANK in (1,2,3,4,5)
	 
--   7. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
	  with cte_all_medals AS (
      SELECT nr.region,
	  count(medal) as total_medals,
	  DENSE_RANK() OVER (ORDER BY count(medal) DESC) AS RANK
	  FROM athelete_events 
	  JOIN noc_regions nr ON athelete_events.noc = nr.noc
	  WHERE medal in('Gold','Silver','Bronze')
      GROUP BY 1
	  ORDER BY count(medal) DESC 
	  )
	  
      SELECT * FROM  cte_all_medals  WHERE RANK in (1,2,3,4,5)
  
  -- 8. List down total gold, silver and broze medals won by each country.
     WITH gold AS (
     SELECT noc , count(medal) as gold
     from athelete_events where medal like 'Gold'
     group by 1 
     order by count(medal) desc
     ),
     silver AS (
     SELECT noc , count(medal) as silver 
     from athelete_events where medal like 'Silver'
     group by 1 
     order by count(medal) desc
      ),
     bronze AS (
     SELECT noc ,count(medal) as bronze
     from athelete_events where medal like 'Bronze'
     group by 1 
     order by count(medal) desc
     ),
     total as (
     SELECT  gold.noc as noc,
     (gold.gold + bronze.bronze  + silver.silver) as total_medals ,
     DENSE_RANK() OVER (ORDER BY (gold.gold + bronze.bronze  + silver.silver) DESC) AS ranking
     FROM gold 
     JOIN silver  on  gold.noc = silver.noc 
     JOIN bronze  on  gold.noc = bronze.noc 
     )
     select  noc_regions.region , total_medals , ranking from total 
     JOIN noc_regions on total.noc = noc_regions.noc
     WHERE ranking in(1,2,3,4,5) 
     order by total_medals DESC 
  
 -- 9. List down total gold, silver and broze medals won by each country corresponding to each olympic games.
    WITH medal_counts AS (
    SELECT 
    noc,
    games AS game,
    SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
    SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
    FROM athelete_events
    WHERE medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY noc, games
    )
    SELECT 
    nr.region,
    mc.game,
    mc.gold,
    COALESCE(mc.silver, 0) AS silver,
    COALESCE(mc.bronze, 0) AS bronze
    FROM medal_counts mc
    JOIN noc_regions nr ON mc.noc = nr.noc
    ORDER BY mc.game ASC;
	
 --10. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
    WITH gold AS (
    SELECT noc, games AS game, COUNT(medal) AS gold
    FROM athelete_events
    WHERE medal = 'Gold'
    GROUP BY noc, games
    ),
    silver AS (
    SELECT noc, games AS game, COUNT(medal) AS silver
    FROM athelete_events
    WHERE medal = 'Silver'
    GROUP BY noc, games
    ),
    bronze AS (
    SELECT noc, games AS game, COUNT(medal) AS bronze
    FROM athelete_events
    WHERE medal = 'Bronze'
    GROUP BY noc, games
    ),
    max_gold AS (
    SELECT game, MAX(gold) AS max_gold
    FROM gold
    GROUP BY game
    ),
    max_silver AS (
    SELECT game, MAX(silver) AS max_silver
    FROM silver
    GROUP BY game
    ),
    max_bronze AS (
    SELECT game, MAX(bronze) AS max_bronze
    FROM bronze
    GROUP BY game
    )
    SELECT 
    g.game AS game,
    CONCAT(nr_gold.region, ':', g.gold) AS gold_winner,
    CONCAT(nr_silver.region, ':', s.silver) AS silver_winner,
    CONCAT(nr_bronze.region, ':', b.bronze) AS bronze_winner
    FROM max_gold mg
    JOIN gold g ON g.game = mg.game AND g.gold = mg.max_gold
    JOIN max_silver ms ON g.game = ms.game
    JOIN silver s ON s.game = ms.game AND s.silver = ms.max_silver
    JOIN max_bronze mb ON g.game = mb.game
    JOIN bronze b ON b.game = mb.game AND b.bronze = mb.max_bronze
    -- Join with noc_regions to get the full country name
    JOIN noc_regions nr_gold ON g.noc = nr_gold.noc
    JOIN noc_regions nr_silver ON s.noc = nr_silver.noc
    JOIN noc_regions nr_bronze ON b.noc = nr_bronze.noc
    ORDER BY g.game ASC;

   --11. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
    WITH gold AS (
    SELECT noc, games AS game, COUNT(medal) AS gold
    FROM athelete_events
    WHERE medal = 'Gold'
    GROUP BY noc, games
    ),
    silver AS (
    SELECT noc, games AS game, COUNT(medal) AS silver
    FROM athelete_events
    WHERE medal = 'Silver'
    GROUP BY noc, games
    ),
    bronze AS (
    SELECT noc, games AS game, COUNT(medal) AS bronze
    FROM athelete_events
    WHERE medal = 'Bronze'
    GROUP BY noc, games
    ),
    total_medals AS (
    SELECT 
    g.noc, 
    g.game, 
    COALESCE(g.gold, 0) + COALESCE(s.silver, 0) + COALESCE(b.bronze, 0) AS total_medals
    FROM gold g
    LEFT JOIN silver s ON g.noc = s.noc AND g.game = s.game
    LEFT JOIN bronze b ON g.noc = b.noc AND g.game = b.game
    ),

 --Find the country with the most gold medals for each game
    max_gold AS (
    SELECT game, MAX(gold) AS max_gold
    FROM gold
    GROUP BY game
    ),
    gold_winner AS (
    SELECT g.game, g.noc, g.gold
    FROM gold g
    JOIN max_gold mg ON g.game = mg.game AND g.gold = mg.max_gold
    ),
 -- Find the country with the most silver medals for each game
    max_silver AS (
    SELECT game, MAX(silver) AS max_silver
    FROM silver
    GROUP BY game
    ),
    silver_winner AS (
    SELECT s.game, s.noc, s.silver
    FROM silver s
    JOIN max_silver ms ON s.game = ms.game AND s.silver = ms.max_silver
    ),
 -- Find the country with the most bronze medals for each game
    max_bronze AS (
    SELECT game, MAX(bronze) AS max_bronze
    FROM bronze
    GROUP BY game
    ),
    bronze_winner AS (
    SELECT b.game, b.noc, b.bronze
    FROM bronze b
    JOIN max_bronze mb ON b.game = mb.game AND b.bronze = mb.max_bronze
    ),
   -- Find the country with the most total medals for each game
   max_total_medals AS (
    SELECT game, MAX(total_medals) AS max_total_medals
    FROM total_medals
    GROUP BY game
     ),
    total_medals_winner AS (
    SELECT tm.game, tm.noc, tm.total_medals
    FROM total_medals tm
    JOIN max_total_medals mtm ON tm.game = mtm.game AND tm.total_medals = mtm.max_total_medals
    )
    SELECT 
    g.game AS game,
    CONCAT(nr_gold.region, ':', g.gold) AS gold_winner,
    CONCAT(nr_silver.region, ':', s.silver) AS silver_winner,
    CONCAT(nr_bronze.region, ':', b.bronze) AS bronze_winner,
    CONCAT(nr_total.region, ':', tm.total_medals) AS total_medals_winner
    FROM gold_winner g
    JOIN silver_winner s ON g.game = s.game
    JOIN bronze_winner b ON g.game = b.game
    JOIN total_medals_winner tm ON g.game = tm.game
    -- Join with noc_regions to get the full country name
    JOIN noc_regions nr_gold ON g.noc = nr_gold.noc
    JOIN noc_regions nr_silver ON s.noc = nr_silver.noc
    JOIN noc_regions nr_bronze ON b.noc = nr_bronze.noc
    JOIN noc_regions nr_total ON tm.noc = nr_total.noc
    ORDER BY g.game ASC;

  --12. In which Sport/Event, Pakistan has won the highest medals?
    SELECT 
    sport, 
    event,
    COUNT(*) AS total_medals
    FROM 
    athelete_events
    WHERE 
    noc = 'PAK'
    GROUP BY 
    sport, event
    ORDER BY 
    total_medals DESC
    LIMIT 1;

 --13. Break down all Olympic Games where India won a medal for Hockey and how many medals in each Olympic Games.
    SELECT 
    year,
    COUNT(*) AS total_hockey_medals
    FROM 
    athelete_events
    WHERE 
    noc = 'PAK'
    AND sport = 'Hockey'
    GROUP BY 
    year
    ORDER BY 
    year;






  