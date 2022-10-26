{% macro funnel(steps=none, event_stream=none, start_date=none, end_date=none) %}
  {{ return(adapter.dispatch('funnel','dbt_product_analytics')(steps, event_stream, start_date, end_date)) }}
{% endmacro %}

{% macro default__funnel(steps, event_stream, start_date, end_date) %}
  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream, start_date, end_date) }}
  {% for step in steps %}
    , event_stream_step_{{ loop.index }} as (
      select event_stream.* 
      from event_stream
      {% if loop.index > 1 %}
        inner join event_stream_step_{{ loop.index - 1 }} as previous_events
          on event_stream.user_id = previous_events.user_id
          and previous_events.event_type = '{{ loop.previtem }}'
          and previous_events.event_date <= event_stream.event_date
      {% endif %}
      where event_stream.event_type = '{{ step }}'
    )

    , step_{{ loop.index }} as (
      select count(distinct user_id) as unique_users 
      from event_stream_step_{{ loop.index }}
    )  

  {% endfor %}

  , event_funnel as (
    {% for step in steps %}
      select '{{ step }}' as event_type, unique_users, {{ loop.index }} as step_index
      from step_{{ loop.index }}
      {% if not loop.last %}
        union all
      {% endif %}
    {% endfor %}
  )

  , final as (
    select event_type
      , unique_users, 1.0 * unique_users / nullif(first_value(unique_users) over(order by step_index), 0) as pct_conversion
      , 1.0 * unique_users / nullif(lag(unique_users) over(order by step_index), 0) as pct_of_previous
    from event_funnel
  )

  select * from final
{% endmacro %}

{% macro snowflake__funnel(steps, event_stream, start_date, end_date) %}
  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream, start_date, end_date) }}

  , steps as (
    {% for step in steps %}
      select
        '{{ step }}' as event_type
        , {{ loop.index }} as index
      {% if not loop.last %}
        union all
      {% endif %}
    {% endfor %}
  )
  , event_funnel as (
    select event_type, count(distinct user_id) as unique_users
    from event_stream
    match_recognize(
        partition by user_id
        order by event_date
        all rows per match
        pattern({% for step in steps %} ({% for i in range(loop.length - loop.index + 1) %} step_{{ loop.index }}+{% endfor %}) {% if not loop.last %} | {% endif %} {% endfor %} )
        define
          {% for step in steps %}
            step_{{ loop.index }} as event_type = '{{ step }}' {% if not loop.last %} , {% endif %}
          {% endfor %}
    )
    group by event_type
  )
  
  , final as (
    select event_funnel.event_type
      , unique_users, cast(unique_users as double) / nullif(first_value(unique_users) over(order by steps.index), 0) as pct_conversion
      , 1.0 * cast(unique_users as double) / nullif(lag(unique_users) over(order by steps.index), 0) as pct_of_previous
    from event_funnel
    left join steps
      on event_funnel.event_type = steps.event_type
    order by steps.index
  )

  select * from final
{% endmacro %}

{% macro trino__funnel(steps, event_stream) %}
  {{ dbt_product_analytics.snowflake__funnel(steps, event_stream) }}
{% endmacro %}


{# 
### EXAMPLE ###
{% set steps = [
  { "alias": "Landing Page Loaded", "event_type": "Page Loaded", "filter": { "page_path": "/" },
  { "event_type": "Form Filled Out" },
  { "alias": "Checkout Page Loaded", "event_type": "Page Loaded", "filter": { "page_path": "/checkout" } },
  { "event_type": "Order Placed" }
]%}
{% set events = event_stream(ref="m_events", user_id="uid", start_date="2022-01-01", end_date="2022-02-01")%}
select {{ funnel(steps, type="unique" }}
from {{ events }}

# note: type defaults to count, but could be unique (based on the user ID column given)
# todo: should i make them define an event stream dataset via meta tags or another macro?

### OUTPUT ###
event_type,events,pct_conversion,pct_of_previous
"Landing Page Loaded",543,1.0,
"Form Filled Out",342,0.63,0.63
"Checkout Page Loaded",102,0.19,0.30
"Order Placed",34,0.06,0.33

#}