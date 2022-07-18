{% macro retention(event_stream, first_action, second_action, start_date, periods=[1,7,14,30,60,120], period_type='day', dimensions=[]) %}
  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream) }}

  , first_events as (
    select user_id, min(event_date) as first_event_date
      {% for dimension in dimensions %}, {{ dimension }} {% endfor %}
    from event_stream
    where event_type = '{{ first_action }}'
    and event_date = '{{ start_date }}'
    group by 1 order by 1
  )

  , first_event_counts as (
    select 
      {% for dimension in dimensions %}, {{ dimension }} {% endfor %}
      , count(*) as unique_users_{{ period_type }}_0
    from first_events
    {% for dimension in dimensions -%} 
      {% if loop.first %} group by {% endif %} {{ loop.index }} 
    {%- endfor %}
  )

  {% for period in periods %}
  , secondary_events_{{ period }} as (
    select {% for dimension in dimensions %} {{ dimension }}, {% endfor %}
    count(distinct first_events.user_id) as unique_users_{{ period_type }}_{{ period }}
    from event_stream
    where event_stream.event_type = '{{ second_action }}'
    and event_stream.event_date >= '{{ start_date }}'
    and event_stream.event_date < '{{ start_date }}' + 'interval {{ period }} {{ period_type }}'
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