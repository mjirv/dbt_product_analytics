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

{% set steps = [
  { "event_type": "placed" },
  { "event_type": "completed" },
  { "event_type": "returned" }
]%}

{{ dbt_product_analytics.funnel(steps=steps, event_stream=events) }}
-- or materialize your event stream and use:
-- {{ dbt_product_analytics.funnel(steps=steps, event_stream=ref('order_events')) }}
```

Output:

```sql
michael=# select * from dbt_product_analytics.funnel_orders ;
 event_type | unique_users |     pct_conversion     |    pct_of_previous
------------+--------------+------------------------+------------------------
 placed     |           15 | 1.00000000000000000000 |
 completed  |            2 | 0.13333333333333333333 | 0.13333333333333333333
 returned   |            1 | 0.06666666666666666667 | 0.50000000000000000000
```

### retention() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/retention.sql))

_Runs a retention analysis, i.e. tells you how many people who did `first_action` on `start_date` came back to do `second_action` in the date windows chosen_

#### Usage

Example:

```sql
{{ dbt_product_analytics.retention(
  event_stream=ref('order_events'),
  first_action='completed',
  second_action='completed',
  start_date='2018-01-17'
)}}
```

Output:

```sql
michael=# select * from dbt_product_analytics.retention_orders ;
 unique_users_day_0 | unique_users_day_1 | unique_users_day_7 | unique_users_day_14 | unique_users_day_30 | unique_users_day_60 | unique_users_day_120
--------------------+--------------------+--------------------+---------------------+---------------------+---------------------+----------------------
                  2 |                  0 |                  0 |                   0 |                   0 |                   0 |                    1
```

Advanced:

Three other parameters are available: `periods`, `period_type`, and `dimensions`.

- **`period`**: The period windows you want look at (defaults to `[1, 7, 14, 30, 60, 120])`
- **`period_type`**: The date type you want to use (defaults to `day`)
- **`dimensions`**: A list of columns from your event stream that you want to group by (defaults to `[]`)

### flows() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/flows.sql))

_Runs a flow analysis, i.e. shows you common paths users take before or after a given event_

#### Usage

Example:

```sql
{{
  dbt_product_analytics.flows(
    event_stream=events,
    primary_event='placed'
  )
}}
```

Output:

```sql
michael=# select * from dbt_product_analytics.flows_orders ;
 event_0 |  event_1  | event_2  | event_3 | event_4 | event_5 | n_events
---------+-----------+----------+---------+---------+---------+----------
 placed  |           |          |         |         |         |       13
 placed  | completed | returned |         |         |         |        1
 placed  | completed |          |         |         |         |        1
```

Advanced:

Three other parameters are available: `n_events_from`, `before_or_after`, and `top_n`.

- **`n_events_from`**: The number of events to include in the flows (defaults to `5`)
- **`before_or_after`**: Whether to look at the events following your `primary_action` or the ones leading up to it (defaults to `'after'`)
- **`top_n`**: How many flows to include (defaults to displaying the top `20`)
