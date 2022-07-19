{% macro flows(event_stream=None, primary_event=None, n_events_from=5, before_or_after='after', top_n=20) %}

  {% if event_stream is none %}
    {{ exceptions.raise_compiler_error('parameter \'event_stream\' must be provided')}}
  {% endif %}

  {% if primary_event is none %}
    {{ exceptions.raise_compiler_error('parameter \'primary_event\' must be provided')}}
  {% endif %}  

  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream) }}

  , flow_events as (
    select
      event_type as event_0
      {% for i in range(n_events_from) %}
        , lead(event_type, {{ i + 1 }}) over(partition by user_id order by event_date) as event_{{ i + 1 }}
      {% endfor %}
    from event_stream
  )

  , flow_counts as (
    select
      *
      , count(*) as n_events
    from flow_events
    where event_0 = '{{ primary_event }}'
    group by 1 {% for i in range(n_events_from) %}, {{ i + 2 }} {% endfor %}
  )

  , final as (
    select *
    from flow_counts
    order by n_events desc
    limit {{ top_n }}
  )

  select * from final
{% endmacro %}