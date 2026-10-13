{{config(materialized = 'table')}}

WITH fct_ratings AS(
    SELECT * FROM {{ref('fct_ratings')}}
),

seed_dates AS (
    SELECT * FROM {{ref('seed_movie_release_dates')}}
)

SELECT
    f.*,
    CASE
        WHEN d.release_date  IS NULL THEN 'unknow'
        ELSE 'known'
    END AS release_info_avaliable

FROM fct_ratings AS f
LEFT JOIN seed_dates AS d
ON f.movie_id = d.movie_id