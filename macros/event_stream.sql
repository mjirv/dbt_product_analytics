{% macro event_stream(
    ref=None,
    event_type_col=None,
    user_id_col=None, 
    date_col=None,
    start_date=None, 
    end_date=None)
%}
  select 1 as test_col
{% endmacro %}