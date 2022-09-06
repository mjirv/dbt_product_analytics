{% macro _run_query(query) %}
    -- {# example usage:
    --     dbt -q run-operation _run_query --args "{\"query\": \"{{ dbt_product_analytics.funnel(steps=[{ 'event_type': 'placed' }, {'event_type': 'completed'}, {'event_type': 'returned'}], event_stream=ref('order_events')) }}\"}"
    --     [{"event_type": "placed", "unique_users": 15.0, "pct_conversion": 1.0, "pct_of_previous": null}, {"event_type": "completed", "unique_users": 2.0, "pct_conversion": 0.13333333333333333, "pct_of_previous": 0.13333333333333333}, {"event_type": "returned", "unique_users": 1.0, "pct_conversion": 0.06666666666666667, "pct_of_previous": 0.5}]
    -- #}
    {% set res = run_query(render(query)) %}
    {% do res.print_json() %}
{% endmacro %}