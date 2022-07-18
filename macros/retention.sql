{% macro retention(event_stream=None, first_action=None, second_action=None, start_date=None, periods=[1,7,14,30,60,120], period_type='day', dimensions=[]) %}
  {% if event_stream is none %}
    {{ exceptions.raise_compiler_error('parameter \'event_stream\' must be provided')}}
  {% endif %}

  {% if first_action is none %}
    {{ exceptions.raise_compiler_error('parameter \'first_action\' must be provided')}}
  {% endif %}

  {% if second_action is none %}
    {{ exceptions.raise_compiler_error('parameter \'second_action\' must be provided')}}
  {% endif %}

  {% if start_date is none %}
    {{ exceptions.raise_compiler_error('parameter \'start_date\' must be provided')}}
  {% endif %}
  
  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream) }}

  , first_events as (
    select distinct user_id
      {% for dimension in dimensions %}, {{ dimension }} {% endfor %}
    from event_stream
    where event_type = '{{ first_action }}'
    and event_date = cast('{{ start_date }}' as date)
  )

  , first_event_counts as (
    select 
      {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
      count(*) as unique_users_{{ period_type }}_0
    from first_events
    {% for dimension in dimensions -%} 
      {% if loop.first %} group by {% endif %} {{ loop.index }} 
    {%- endfor %}
  )

  {% for period in periods %}
  , secondary_events_{{ period }} as (
    select {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
    count(distinct user_id) as unique_users_{{ period_type }}_{{ period }}
    from event_stream
    where event_type = '{{ second_action }}'
    and event_date > cast('{{ start_date }}' as date)
    and event_date < {{ dbt_product_analytics._dateadd(datepart=period_type, interval=period, from_date_or_timestamp="cast('" ~ start_date ~ "' as date)") }}
    and user_id in (
      select user_id from first_events
    )
    {% for dimension in dimensions -%}
      {% if loop.first %} group by {% endif %} {{ loop.index }}
    {%- endfor %}
  )
  {% endfor %}

  , final as (
    select 
      {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
      unique_users_{{ period_type }}_0,
      {% for period in periods %} unique_users_{{ period_type }}_{{ period }} {% if not loop.last %}, {% endif %} {% endfor %}
    from first_event_counts
    {% for period in periods %}
      left join secondary_events_{{ period }}
        on 1 = 1
        {% for dimension in dimensions %}
          and first_event_counts.{{ dimension }} = secondary_events_{{ period }}.{{ dimension }}
        {% endfor %}
    {% endfor %}
  )

  select * from final
{% endmacro %}