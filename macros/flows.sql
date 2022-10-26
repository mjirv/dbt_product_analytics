{% macro flows(
  event_stream=None,
  primary_event=None, 
  n_events_from=5, 
  before_or_after='after', 
  top_n=20, 
  start_date=none, 
  end_date=none) 
%}

  {% if event_stream is none %}
    {{ exceptions.raise_compiler_error('parameter \'event_stream\' must be provided')}}
  {% endif %}

  {% if primary_event is none %}
    {{ exceptions.raise_compiler_error('parameter \'primary_event\' must be provided')}}
  {% endif %}  

  with event_stream as {{ dbt_product_analytics._select_event_stream(event_stream, start_date, end_date) }}

  , flow_events as (
    select
      {% if before_or_after == 'after' %} event_type as event_0 {% endif %}
      {% for i in range(n_events_from) %}
        {% if before_or_after == 'before' %} {% set index = n_events_from - i %} {% else %} {% set index = i + 1 %} {% endif %}
        {% if before_or_after == 'before' %}{% if not loop.first %},{% endif %}lag{% else %}, lead{% endif %}(event_type, {{ index }}) over(partition by user_id order by event_date) as event_{{ index }}
      {% endfor %}
      {% if before_or_after == 'before' %}, event_type as event_0 {% endif %}
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