{% macro event_stream(
    from=none,
    event_type_col=none,
    user_id_col=none, 
    date_col=none,
    start_date=none, 
    end_date=none)
%}
  {{ return(adapter.dispatch('event_stream', 'dbt_product_analytics')(from, event_type_col, user_id_col, date_col, start_date, end_date)) }}
{% endmacro %}

{% macro default__event_stream(from, event_type_col, user_id_col, date_col, start_date, end_date) %}
  select {{ event_type_col }} as event_type, {{ user_id_col }} as user_id, {{ date_col }} as event_date
  from {{ from }}
  where 1 = 1
  {% if start_date is not none %}
    and {{ date_col }} >= {{ dbt_product_analytics._cast_to_date(start_date) }}
  {% endif %}
  {% if end_date is not none %}
    and {{ date_col }} < {{ dbt_product_analytics._cast_to_date(end_date) }}
  {% endif %}
{% endmacro %}
