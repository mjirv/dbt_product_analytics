{% macro _select_event_stream(event_stream, start_date=none, end_date=none) -%}
  ( {% if not (event_stream|string|trim).startswith('select ') %} select * from {% endif %} {{ event_stream }}
    {% if start_date or end_date %} where 1 = 1 {% endif %}
    {% if start_date %} and event_date >= '{{ start_date }}' {% endif %}
    {% if end_date %} and event_date < '{{ end_date }}' {% endif %}
   )
{%- endmacro %}