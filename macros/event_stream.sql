{% macro event_stream(
    from=none,
    event_type_col=none,
    user_id_col=none, 
    date_col=none,
    start_date=none, 
    end_date=none)
%}
  select {{ event_type_col }} as event_type, {{ user_id_col }} as user_id, {{ date_col }} as event_date
  from {{ from }}
  where 1 = 1
  {% if start_date is not none %}
    and {{ date_col }} >= '{{ start_date }}'
  {% endif %}
  {% if end_date is not none %}
    and {{ date_col }} < '{{ end_date }}'
  {% endif %}
{% endmacro %}