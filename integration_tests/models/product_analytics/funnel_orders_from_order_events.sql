{% set steps = ["placed", "completed", "returned"] %}

{{ dbt_product_analytics.funnel(steps=steps, event_stream=ref('order_events')) }}