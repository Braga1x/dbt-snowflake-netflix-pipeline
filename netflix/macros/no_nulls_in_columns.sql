{% macro no_nulls_in_columns(model) %}
    SELECT * FROM {{ model }}
    WHERE {% for col in dbt_utils.get_filtered_columns_in_relation(model) %}
        {{ col }} IS NULL OR
    {% endfor %}
    FALSE


{% endmacro %}