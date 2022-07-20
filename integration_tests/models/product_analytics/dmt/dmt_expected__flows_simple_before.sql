select 
  cast(null as varchar) as event_5
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_3
  , cast(null as varchar) as event_2
  , cast(null as varchar) as event_1
  , 'placed' as event_0
  , 5 as n_events

union all

select 
  cast(null as varchar) as event_5
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_3
  , 'completed' as event_2
  , 'returned' as event_1
  , 'placed' as event_0
  , 1 as n_events