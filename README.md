# dbt Product Analytics

A [dbt](https://docs.getdbt.com/) package for doing product analytics.

_Currently supports event streams and funnel analysis. More features will be added soon!_

## Installation

Add the following to your `packages.yml`:

```yaml
- package: mjirv/dbt_product_analytics
  version: [">=0.1.0"]
```

## Usage

**dbt Product Analytics** provides four macros: `event_stream()`, `funnel()`, `retention()`, and `flows()`.

Use them in models and analyses like any other dbt macro.

### event_stream() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/event_stream.sql))

_Transforms any time series model with a user ID and event labels into a standardized event stream format._

#### Usage

```sql
{{ dbt_product_analytics.event_stream(
    from=ref('orders'),
    event_type_col="status",
    user_id_col="customer_id",
    date_col="order_date",
    start_date="2018-01-01",
    end_date="2019-01-01") }}
```

### funnel() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/funnel.sql))

_Runs a funnel analysis, i.e. tells you how many users performed step 1 followed by step 2 followed by step 3 etc._

#### Usage

##### Example:

```sql
{% set events =
  dbt_product_analytics.event_stream(
    from=ref('orders'),
    event_type_col="status",
    user_id_col="customer_id",
    date_col="order_date",
    start_date="2018-01-01",
    end_date="2019-01-01")
%}

{% set steps = ["placed", "completed", "returned" ] %}

{{ dbt_product_analytics.funnel(steps=steps, event_stream=events) }}
-- or materialize your event stream and use:
-- {{ dbt_product_analytics.funnel(steps=steps, event_stream=ref('order_events')) }}
```

##### Output:

```sql
michael=# select * from dbt_product_analytics.funnel_orders ;
event_type  unique_users  pct_conversion      pct_of_previous  
----------  ------------  ------------------  -----------------
placed      15            1.0                                  
completed   2             0.133333333333333   0.133333333333333
returned    1             0.0666666666666667  0.5              
```

##### Advanced:

Two optional parameters are available: `start_date`, and `end_date`.

- **`start_date`**: Filters your event stream for only events on or after this date
- **`end_date`**: Filters your event stream for only events before this date

### retention() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/retention.sql))

_Runs a retention analysis, i.e. tells you how many people who did `first_action` came back to do `second_action` on or after 1, 7, 14 days (or weeks, months, years), etc._

#### Usage

##### Example:

```sql
{{ dbt_product_analytics.retention(
  event_stream=ref('order_events'),
  first_action='completed',
  second_action='completed',
)}}
```

##### Output:

```sql
michael=# select * from dbt_product_analytics.retention_orders ;
period  unique_users  pct_users        
------  ------------  -----------------
1       43            0.693548387096774
7       41            0.661290322580645
14      37            0.596774193548387
30      28            0.451612903225806
60      2             0.032258064516129
```

##### Advanced:

Five optional parameters are available: `periods`, `period_type`, `group_by`, `start_date`, and `end_date`.

- **`period`**: The period windows you want look at (defaults to `[1, 7, 14, 30, 60, 120])`
- **`period_type`**: The date type you want to use (defaults to `day`)
- **`group_by`**: A column from your event stream that you want to group by (defaults to `null`)
- **`start_date`**: Filters your event stream for only events on or after this date
- **`end_date`**: Filters your event stream for only events before this date

### flows() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/flows.sql))

_Runs a flow analysis, i.e. shows you common paths users take before or after a given event_

#### Usage

##### Example:

```sql
{{
  dbt_product_analytics.flows(
    event_stream=events,
    primary_event='placed'
  )
}}
```

##### Output:

```sql
michael=# select * from dbt_product_analytics.flows_orders ;
event_0  event_1    event_2   event_3  event_4  event_5  n_events
-------  ---------  --------  -------  -------  -------  --------
placed                                                   13      
placed   completed                                       1       
placed   completed  returned                             1       
```

##### Advanced:

Five optional parameters are available: `n_events_from`, `before_or_after`, `top_n`, `start_date`, and `end_date`.

- **`n_events_from`**: The number of events to include in the flows (defaults to `5`)
- **`before_or_after`**: Whether to look at the events following your `primary_action` or the ones leading up to it (defaults to `'after'`)
- **`top_n`**: How many flows to include (defaults to displaying the top `20`)
- **`start_date`**: Filters your event stream for only events on or after this date
- **`end_date`**: Filters your event stream for only events before this date
