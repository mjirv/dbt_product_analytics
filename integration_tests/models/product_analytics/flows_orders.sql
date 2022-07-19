{{ 
  dbt_product_analytics.flows(
    event_stream=ref('order_events'), 
    primary_event='placed'
  )
}}