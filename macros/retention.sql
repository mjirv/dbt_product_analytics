{% macro retention(event_stream=None, first_action=None, second_action=None, start_date=None, end_date=None, periods=[0,1,7,14,30,60,120], period_type='day', dimensions=[]) %}
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
    select 
      {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
      count(distinct user_id) as unique_users_total
    from event_stream
    {% for dimension in dimensions -%} 
      {% if loop.first %} group by {% endif %} {{ loop.index }} 
    {%- endfor %}
  )

  {% for period in periods %}
  , secondary_events_{{ period }} as (
    select {{ period }} as period,
    {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
    count(distinct user_id) as unique_users
    from event_stream
    where event_type = '{{ second_action }}'
    and event_date >= {{ dbt_product_analytics._dateadd(datepart=period_type, interval=period, from_date_or_timestamp=dbt_product_analytics._cast_to_date(start_date)) }}
    {% if end_date %} and event_date < {{ dbt_product_analytics._cast_to_date(end_date) }} {% endif %}
    and user_id in (
      select user_id from first_events
    )

    group by period
    {% for dimension in dimensions -%}
      {{ dimension }}
    {%- endfor %}
  )
  {% endfor %}

  , final as (
    select 
      period, 
      {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
      unique_users,
      1.0 * unique_users / unique_users_total as pct_users
    from first_events
    left join (
      {% for period in periods %}
        select * from secondary_events_{{ period }}
        {% if not loop.last %}
          union all
        {% endif %}
      {% endfor %}
    ) secondary_events on  1 = 1
    {% for dimension in dimensions %}
      and first_events.{{ dimension }} = secondary_events_{{ period }}.{{ dimension }}
    {% endfor %}
  )

  select * from final
{% endmacro %}