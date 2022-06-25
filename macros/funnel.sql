{% macro funnel(steps=None, event_stream=None, type='count', start_time=None, end_time=None) %}
  with event_stream as ( {{ event_stream }} )
  select * from event_stream
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