{% macro _dateadd(datepart, interval, from_date_or_timestamp) %}
  {{ return(adapter.dispatch('_dateadd', 'dbt_product_analytics')(datepart, interval, from_date_or_timestamp)) }}
{% endmacro %}

{% macro default___dateadd(datepart, interval, from_date_or_timestamp) %}
  {{ return(adapter.dispatch('dateadd', 'dbt')(datepart, interval, from_date_or_timestamp)) }}
{% endmacro %}

{% macro trino___dateadd(datepart, interval, from_date_or_timestamp) %}
  {{ from_date_or_timestamp }} + interval '{{ interval }}' {{ datepart }}
{% endmacro %}

{% macro sqlite___dateadd(datepart, interval, from_date_or_timestamp) %}
  date({{ from_date_or_timestamp }}, '+{{ interval }} {{ datepart }}')
{% endmacro %}