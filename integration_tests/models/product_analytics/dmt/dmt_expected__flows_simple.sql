select 
  'placed' as event_0
  , 'completed' as event_1
  , cast(null as varchar) as event_2
  , cast(null as varchar) as event_3
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_5
  , 3 as n_events

union all

select 
  'placed' as event_0
  , 'completed' as event_1
  , 'returned' as event_2
  , 'returned' as event_3
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_5
  , 1 as n_events

union all

select 
  'placed' as event_0
  , 'completed' as event_1
  , 'returned' as event_2
  , cast(null as varchar) as event_3
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_5
  , 1 as n_events

union all

select 
  'placed' as event_0
  , 'returned' as event_1
  , cast(null as varchar) as event_2
  , cast(null as varchar) as event_3
  , cast(null as varchar) as event_4
  , cast(null as varchar) as event_5
  , 1 as n_events