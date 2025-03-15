select * from netflix
exec sp_rename 'dbo.netflix.cast','casts','Column' 
-- 1 Count the Number of Movies vs TV Shows
select 
type,
count(*) as 'Content Type'
from netflix
group by type
go
-- 2 Find the most common rating for movies and TV shows
select 
type,
rating,
[Total Rating]
from 
(
select 
type,
rating,
COUNT(*) as 'Total Rating',
RANK() over(partition by type order by COUNT(*) desc) as 'Ranking'
from netflix
group by type,rating
) s1 
where Ranking = 1
go
-- 3 List all movies released in a specific year (e.g., 2020)
select 
*
from netflix
where release_year = 2020
go
-- 4 Find the top 5 countries with the most content on Netflix
select
top 5
countries,
COUNT(*) as 'Most Content'
from
(select
*,
value as countries
from netflix cross apply string_split([country],',')) s1
group by countries
order by [Most Content] desc
go
-- 5 Identify the longest movies
select 
title,
LEFT(duration,CHARINDEX(' ',duration)) as 'Longest Movies'
from netflix
order by [Longest Movies] desc
go
-- 6 Find content added in the last 5 years
select 
*
from netflix
where date_added > DATEADD(YEAR,-5,GETDATE())
go

-- 7 Find all the movies/TV shows by director 'Rajiv Chilaka'!
select 
show_id,type,title,director
from netflix
where director like '%Rajiv Chilaka%'
go

-- 8 List all TV shows with more than 5 seasons
select 
*
from netflix
where duration like '%Seasons%' and  
cast(LEFT(duration,CHARINDEX(' ',duration)-1) as int) > 5
go

-- 9 Count the number of content items in each genre
with ContentItems_CTE(Genre,Total_Items)
as (
select 
TRIM(value) as 'Genre' ,
count(*) as 'Total_Items'
from netflix cross apply string_split([listed_in],',')
group by TRIM(value)
)
select * from  ContentItems_CTE
order by Total_Items desc
go
-- 10
/* 
finding the top 5 years with the highest number of content
releases for a specific country (e.g. Australia) on Netflix. 
*/
declare @myCountry varchar(30)
set @myCountry = 'Australia'
select top 5
	trim(value) as 'Country',
	DATEPART(YEAR,date_added) as 'Years',
	COUNT(*) as 'AVG_Content'
from netflix cross apply string_split([country],',')
where TRIM(value) = @myCountry
group by DATEPART(YEAR,date_added),trim(value)
order by [AVG_Content] desc

go
-- 11 List all movies that are documentaries

select 
*
from netflix
where LOWER(listed_in) like '%documentaries'
go

-- 12 Find all content without a director
select 
*
from netflix
where director is null
go

-- 13 Find how many movies actor 'Salman Khan' appeared in last 10 years!

WITH SalmanKhan_cte (Years, Participations) AS (
    SELECT 
        release_year AS Years,
        COUNT(*) AS Participations
    FROM netflix 
    WHERE release_year > YEAR(GETDATE()) - 10 
    AND casts LIKE '%Salman Khan%'
    GROUP BY release_year
)
SELECT * FROM SalmanKhan_cte;
go

-- 14 Find the top 10 actors who have appeared in the highest number of movies produced in United States.

select top 10
trim(value) as actors,
COUNT(*) as Participations
from netflix cross apply string_split([casts],',')
where casts is not null and trim(country) like '%United States%'
group by trim(value)
order by [Participations] desc
go

-- 15 
/* 
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

select 
Category,
COUNT(*) as Total_Items
from 
(
select 
	case
		when description like '%kill%' or description like '%violence%' then 'Bad'
		else 'Good'
	end as 'Category'
from netflix
) s1
group by Category