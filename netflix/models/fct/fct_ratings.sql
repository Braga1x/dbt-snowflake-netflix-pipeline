WITH src_ratings AS (
    SELECT * FROM {{ ref('src_ratings') }}
)

SELECT 
    user_id,
    movie_id,
    rating,
    rating_timestamp
FROM src_ratings
WHERE rating IS NOT NULL

