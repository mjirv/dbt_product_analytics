# dbt Product Analytics

A dbt package for doing product analytics.

_Currently supports event streams and funnel analysis. More features will be added soon!_

## Installation

Add the following to your `packages.yml`:

```yaml
- git: "https://github.com/mjirv/dbt_product_analytics.git"
  revision: 0.0.1
```

## Usage

**dbt Product Analytics** provides two macros: `event_stream()` and `funnel()`.

Use them in models and analyses like any other dbt macro.

### event_stream() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/event_stream.sql))

_Transforms any time series model with a user ID and event labels into a standardized event stream format._

#### Usage

```python
{{ dbt_product_analytics.event_stream(
    from="orders",
    event_type_col="status",
    user_id_col="customer_id",
    date_col="order_date",
    start_date="2018-01-01",
    end_date="2019-01-01") }}
```

### funnel() ([source](https://github.com/mjirv/dbt_product_analytics/blob/main/macros/funnel.sql))

_Runs a funnel analysis, i.e. tells you how many users performed step 1 followed by step 2 followed by step 3 etc._

#### Usage

```python
{% set events =
  dbt_product_analytics.event_stream(
    from="orders",
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
```
