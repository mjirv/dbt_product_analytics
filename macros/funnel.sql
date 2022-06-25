{% macro funnel(steps=none, event_stream=none, type='count') %}
  with event_stream as ( {{ event_stream }} )
  {% for step in steps %}
    , step_{{ loop.index }} as (
      select count(*) as events from event_stream where event_type = '{{ step.event_type }}'
    )
  {% endfor %}

  , event_funnel as (
    {% for step in steps %}
      select '{{ step.event_type }}' as event_type, events
      from step_{{ loop.index }}
      {% if not loop.last %}
        union all
      {% endif %}
    {% endfor %}
  )

  , final as (
    select event_type
    , events, 1.0 * events / first_value(events) over() as pct_conversion
    , 1.0 * events / lag(events) over() as pct_of_previous
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