{% set events = 
  dbt_product_analytics.event_stream(
    from=ref('orders'), 
    event_type_col="status",
    user_id_col="customer_id", 
    date_col="order_date",
    start_date="2018-01-01", 
    end_date="2019-01-01") 
%} 

{{ 
  dbt_product_analytics.flows(
    event_stream=events, 
    primary_event='placed'
  )
}}