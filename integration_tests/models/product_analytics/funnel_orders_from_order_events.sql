{% set steps = [
  { "event_type": "placed" },
  { "event_type": "completed" },
  { "event_type": "returned" }
]%}

{{ dbt_product_analytics.funnel(steps=steps, event_stream=ref('order_events')) }}