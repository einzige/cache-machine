# cache-machine !(http://img195.imageshack.us/img195/5371/cachemachinefinal2.png)

An ActiveRecord mixin that helps managing cached content in a Ruby on Rails application with complex data update dependencies.

Cache Machine provides
* high-level methods for accessing cached content using page names, numbers, time stamps etc,
* a DSL to describe update dependencies between the data models underlying the cached content,
* automatic cache invalidation based on those explicitly modeled data update dependencies.

You will find Cache Machine useful if you:
* use Memcache to cache fragments of a web site that contain data from a variety of underlying data models
* anytime one of the underlying data models changes, all the cached page fragments in which this data model occurs - and only those - need to be invalidated/updated
* you have many data models, cached fragments, and many data models used inside each cached fragment

Cache Machine depends only on the Rails.cache API and is thereby library agnostic.

# Usage

```ruby
# Fetch cache of venues collection on model_instance.
@neighborhood.fetch_cache_of(:venues) { venues }

# Specify format.
@neighborhood.fetch_cache_of(:venues, :format => :json) { venues.to_json }

# Paginated content.
@neighborhood.fetch_cache_of(:venues, :page => 2) { venues.paginate(:page => 2) }
```

In you target model define <b>cache map</b>:

```ruby
cache_map :venues  => [:hotspots, :today_events],
          :cities  => [:venues],
          :streets => :hotspots,
          :users
```

This example shows you how changes of one collection affect on invalidation process.
For each record of your target model:

- Cache for <b>users</b> collection associated with object of your target model is invalidated when changing (_add_, _remove_, _update_) the _users_ collection
- Cache for <b>venues</b> collection associated with object of your target model is invalidated when changing the _venues_ collection associated with that object
- Cache for <b>venues</b> collection associated with object of your target model is invalidated when changing the _cities_ collection. In this case machine automatically invalidates _hotspots_ and _today_events_
- Cache for <b>cities</b> collection associated with object of your target model is invalidated when changing the _cities_ collection
- Cache for <b>hotspots</b> collection is invalidated when changing the _venues_ collection
- Cache for <b>hotspots</b> collection is invalidated when changing the _streets_ collection
- Cache for <b>hotspots</b> collection is invalidated when changing the _cities_ collection
- Cache for <b>today_events</b> collection is invalidated when changing the _venues_ collection
- Cache for <b>today_events</b> collection is invalidated when changing the _cities_ collection

<b>Cache map may contain any name, whatever you want. But invalidation process starts only when ActiveRecord collection is changed.</b>


## Custom cache invalidation

### Using timestamps
Suppose you need to reset cache of _schedule_of_events_ every day.

```ruby
@lady_gaga.fetch_cache_of :schedule_of_events, :timestamp => lambda { Date.today } do
  @lady_gaga.events.where(:date.gt => Date.today)
end
```

### Using Cache Machine timestamps
Suppose you need to reset cache of _tweets_ every 10 minutes.

```ruby
class LadyGagaPerformer < ActiveRecord::Base
  define_timestamp :tweets_timestamp, :expires_in => 10.minutes
end

#...

# Somewhere
@lady_gaga.fetch_cache_of :tweets, :timestamp => :tweets_timestamp do
  TwitterApi.fetch_tweets_for @lady_gaga
end
```

Suppose you need custom timestamp value.

```ruby
class LadyGagaPerformer < ActiveRecord::Base
  define_timestamp(:tweets_timestamp) { Time.now.to_i + self.id }
end

#...

# Somewhere
@lady_gaga.fetch_cache_of :tweets, :timestamp => :tweets_timestamp do
  TwitterApi.fetch_tweets_for @lady_gaga
end
```

Note what timestamp declarations work in object scope. Lets take an example:

```ruby
class LadyGagaPerformer < ActiveRecord::Base
  define_timestamp (:tweets_timestamp) { tweets.last.updated_at.to_i }

  has_many :tweets
end

class Tweet < ActiveRecord::Base
  belongs_to :lady_gaga_performer
end
```

### Using methods as timestamps
Suppose you have your own really custom cache key.

```ruby
class LadyGagaPerformer < ActiveRecord::Base
  def my_custom_cache_key
    rand(100) + rand(1000) + rand(10000)
  end
end

#...

# Somewere
@lady_gaga.fetch_cache_of(:something, :timestamp => :my_custom_cache_key) { '...' }
```

### Using class timestamps
Suppose you need to fetch cached content of one of your collections.

```ruby
Rails.cache.fetch(MyModel.timestamped_key) { '...' }
```

Want to see collection timestamp?

```ruby
MyModel.timestamp
```

### Manual cache invalidation
```ruby
# For classes.
MyModel.reset_timestamp

# For collections.
@lady_gaga.delete_cache_of :events

# For timestamps.
@lady_gaga.reset_timestamp_of :events

# You can reset all associated caches using map.
@lady_gaga.delete_all_caches
```

## Cache formats
Cache Machine invalidates cache using a couple of keys with the different formats.
Default formats are: EHTML, HTML, JSON, and XML.

This means you call 5 times for cache invalidation (1 time without specifying format) with different keys. Sometimes it is too much. Cache machine allows you to set your own formats. Just place in your environment config or in initializer the following:

```ruby
CacheMachine::Cache.formats = [:doc, :pdf]
```

Or if you do not want to use formats at all:

```ruby
CacheMachine::Cache.formats = nil
```

Then use:

```ruby
@lady_gaga.fetch_cache_of(:new_songs, :format => :doc) { "LaLaLa".to_doc }
@lady_gaga.fetch_cache_of(:new_songs, :format => :pdf) { "GaGaGa".to_pdf }
```

Cache Machine will invalidate cache for each format you specified in config.

## Working with paginated content
Suppose you installed WillPaginate gem and want to cache each page with fetched results separately.

```ruby
class TweetsController < ApplicationController

  def index
    @tweets = @lady_gaga.fetch_cache_of(:tweets, :page => params[:page]) do
      Tweet.all.paginate(:page => params[:page])
    end
  end
end
```

Cache Machine will use `:page` as a part of cache key and will invalidate each page on any change in associated collection.

## ActionView helper
From examples above:

```ruby
<%= cache_for @lady_gaga, :updoming_events do %>
  <p>Don't hide yourself in regret
     Just love yourself and you're set</p>
<% end %>
```

The `cache_for` method automatically sets EHTML format on cache key.


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
