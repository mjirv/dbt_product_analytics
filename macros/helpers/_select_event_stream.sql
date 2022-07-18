{% macro _select_event_stream(event_stream) -%}
  ( {% if not (event_stream|string|trim).startswith('select ') %} select * from {% endif %} {{ event_stream }} )
{%- endmacro %}