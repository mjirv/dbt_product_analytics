{{ dbt_product_analytics.retention(
  event_stream=ref('order_events'),
  first_action='completed',
  second_action='completed',
  start_date='2018-01-01',
  end_date='2018-02-01'
)}}