{% macro _cast_to_date(str) %}
  {{ return(adapter.dispatch('_cast_to_date', 'dbt_product_analytics')(str)) }}
{% endmacro %}

{% macro default___cast_to_date(str) %}
    cast('{{ str }}' as date)
{% endmacro %}

{% macro sqlite___cast_to_date(str) %}
    '{{ str }}'
{% endmacro %}