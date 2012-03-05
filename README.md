# ![cache-machine](http://img195.imageshack.us/img195/5371/cachemachinefinal2.png)

An ActiveRecord mixin that helps managing cached content in a Ruby on Rails application with complex data update dependencies.

Cache Machine provides:

- high-level methods for accessing cached content using page names, numbers, time stamps etc,
- a DSL to describe update dependencies between the data models underlying the cached content,
- automatic cache invalidation based on those explicitly modeled data update dependencies.

You will find Cache Machine useful if you:

- use Memcache to cache fragments of a web site that contain data from a variety of underlying data models
- anytime one of the underlying data models changes, all the cached page fragments in which this data model occurs - and only those - need to be invalidated/updated
- you have many data models, cached fragments, and many data models used inside each cached fragment
- you want to update cache from background job (i.e. cache-sweeper does not know about your changes)

Cache Machine is library agnostic. You can use your own cache adapters (see below).

# Usage

Setup your cache dependencies in config/initializers/cache-machine.rb using <b>cache map</b>. Very similar to Rails routes:

```ruby
CacheMachine::Cache::Map.new.draw do
  resource City do
    collection :streets do
      member :houses
    end

    collection :houses do
      member :bricks
      member :windows
    end
  end

  resource Street do
    collection :houses
    collection :walls
  end

  resource House do
    collection :walls, :scope => :vertical, :timestamp => false do
      members :front_walls, :side_walls
      member :bricks
      member :windows
    end
  end
end
```

In this case your models should look like this:

```ruby
class City < ActiveRecord::Base
  has_many :streets
  has_many :houses, :through => :streets
end

class Street < ActiveRecord::Base
  belongs_to :city
  has_many :houses
  has_many :walls, :through => :houses
end

class House < ActiveRecord::Base
  belongs_to :street
  has_many :walls
end

class Wall < ActiveRecord::Base
  belongs_to :house
  # has_many :bricks
end
```

This example shows you how changes in your database affect on cache:

- When you create/update/destroy any <b>wall</b>:
  - cache of <b>walls collection</b> expired for <b>house</b> associated with that updated/created/destroyed wall
  - cache of <b>walls collection</b> expired for <b>street</b> (where wall's house is located) associated with that updated/created/destroyed
  - cache of <b>front_walls</b> and <b>side_walls</b> expired for <b>house</b> associated with that updated/created/destroyed wall
  - cache of <b>bricks</b> expired for <b>house</b> associated with that updated/created/destroyed wall
  - cache of <b>windows</b> expired for <b>house</b> associated with that updated/created/destroyed wall
- When you create/update/destroy any <b>house</b>:
  - cache of <b>houses</b> updated for associated <b>street</b>
  - cache of <b>houses</b> updated for associated <b>city</b>
- When you create/update/destroy any <b>street</b>:
  - cache of <b>streets</b> updated for associated <b>city</b>
  - cache of <b>houses</b> updated for associated <b>city</b>
- ... :)

<b>Member may have any name, whatever you want. But invalidation process starts only when collection is changed.</b>

## Custom cache invalidation

### Using timestamps
Timestamps allow you to build very complex and custom cache dependencies.

In your model:

```ruby
class House < ActiveRecord::Base
  define_timestamp(:walls_timestamp) { [ bricks.count, windows.last.updated_at ] }
end
```

Anywhere else:

```ruby
@house.fetch_cache_of :walls, :timestamp => :walls_timestamp do
  walls.where(:built_at => Date.today)
end
```

This way you add additional condition to cache-key used for fetching data from cache:
Any time when bricks count is changed or any window is updated your cache key will be changed and block will return fresh data.
Timestamp should return array or string.

### Using Cache Machine timestamps
Suppose you need to reset cache of _tweets_ every 10 minutes.

```ruby
class LadyGaga < ActiveRecord::Base
  define_timestamp :tweets_timestamp, :expires_in => 10.minutes do
    ...
  end
end

#...

# Somewhere
@lady_gaga.fetch_cache_of :tweets, :timestamp => :tweets_timestamp do
  TwitterApi.fetch_tweets_for @lady_gaga
end
```

```fetch_cache_of``` block uses same options as Rails.cache.fetch. You can easily add _expires_in_ option in it directly.

```ruby
@house.fetch_cache :bricks, :expires_in => 1.minute do
 ...
end
```

Cache Machine stores timestamps for each of your model declared as resource in cache map.

```ruby
House.timestamp
```
Each time your houses collection is changed timestamp will change its value.
You can disable this callback in your cache map:

```ruby
CacheMachine::Cache::Map.new.draw do
  resource House, :timestamp => false
end
```

### Manual cache invalidation

```ruby
# For classes.
House.reset_timestamp

# For collections.
@house.delete_cache :bricks

# For timestamps.
@house.reset_timestamp :bricks

# You can reset all associated caches using map.
@house.delete_all_caches
```

## Associations cache
You can fetch ids of an association from cache.

```ruby
@house.association_ids(:bricks) # will return array of ids
```
You can fetch associated objects from cache.

```ruby
@house.associated_from_cache(:bricks) # will return scope of relation with condition to ids from cache map.
```

## ActionView helper
From examples above:

```erb
<%= cache_for @lady_gaga, :upcoming_events, :timestamp => :each_hour do %>
  <p>Don't hide yourself in regret
     Just love yourself and you're set</p>
<% end %>
```

## Adapters
Cache Machine supports different types for storing cache:

- <b>cache map adapter</b> contains ids of relationships for each object from cache map
- <b>timestamps adapter</b> contains timestamps
- <b>content (storage) adapter</b> contains cached content itself (usually strings, html, etc)

You can setup custom adapters in your environment:

```ruby
url = "redis://user:pass@host.com:9383/"
uri = URI.parse(url)
CacheMachine::Cache.timestamps_adapter = CacheMachine::Adapters::Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
CacheMachine::Cache.storage_adapter = CacheMachine::Adapters::Rails.new
CacheMachine::Cache.map_adapter = CacheMachine::Adapters::Rails.new
```
Default adapter uses standard ```Rails.cache``` API.

Redis adapter is available in cache-machine-redis gem, please check out [here](http://github.com/zininserge/cache-machine-redis).

## Rake tasks
Cache machine will produce SQL queries on each update in collection until all map of associations will stored in cache.
You can "prefill" cache map running:
```rake cache_machine:fill_associations_map```

## Contributing to cache-machine

1. Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
2. Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
3. Fork the project
4. Start a feature/bugfix branch
5. Commit and push until you are happy with your contribution
6. Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
7. Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 PartyEarth LLC. See LICENSE.txt for details.