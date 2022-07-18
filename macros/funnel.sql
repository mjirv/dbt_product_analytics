{% macro funnel(steps=none, event_stream=none) %}
  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream) }}
  {% for step in steps %}
    , event_stream_step_{{ loop.index }} as (
      select event_stream.* 
      from event_stream
      {% if loop.index > 1 %}
        inner join event_stream_step_{{ loop.index - 1 }} as previous_events
          on event_stream.user_id = previous_events.user_id
          and previous_events.event_type = '{{ loop.previtem.event_type }}'
          and previous_events.event_date <= event_stream.event_date
      {% endif %}
      where event_stream.event_type = '{{ step.event_type }}'
    )

    , step_{{ loop.index }} as (
      select count(distinct user_id) as unique_users 
      from event_stream_step_{{ loop.index }}
    )  

  {% endfor %}

  , event_funnel as (
    {% for step in steps %}
      select '{{ step.event_type }}' as event_type, unique_users
      from step_{{ loop.index }}
      {% if not loop.last %}
        union all
      {% endif %}
    {% endfor %}
  )

  , final as (
    select event_type
    , unique_users, 1.0 * unique_users / nullif(first_value(unique_users) over(), 0) as pct_conversion
    , 1.0 * unique_users / nullif(lag(unique_users) over(), 0) as pct_of_previous
    from event_funnel
  )

  select * from final
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