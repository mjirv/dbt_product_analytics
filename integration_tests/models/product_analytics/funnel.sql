with events as ({{ 
  dbt_product_analytics.event_stream(
    ref="orders", 
    user_id_col="customer_id", 
    date_col="order_date",
    start_date="2019-01-01", 
    end_date="2020-01-01") 
  }})

select {{ dbt_product_analytics.funnel(steps, type="unique") }}
from events