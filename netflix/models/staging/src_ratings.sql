WITH raw_ratings AS (
    SELECT * FROM MOVIELENS.RAW.RAW_RATINGS
)

SELECT 
    userId AS user_id,
    movieId AS movie_id,
    rating,
    TO_TIMESTMAP_LTZ(timestamp) AS rating_timestamp
FROM raw_ratings