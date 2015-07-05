# JiraCache

Fetches data from JIRA and caches it in a MongoDB store.

This allows you to build applications performing complex operations on a large number of JIRA content without the JIRA's API latency.

[![Build Status](https://travis-ci.org/rchampourlier/jira_cache.svg)](https://travis-ci.org/rchampourlier/jira_cache)
[![Code Climate](https://codeclimate.com/github/rchampourlier/jira_cache/badges/gpa.svg)](https://codeclimate.com/github/rchampourlier/jira_cache)
[![Coverage Status](https://coveralls.io/repos/rchampourlier/jira_cache/badge.svg?branch=master)](https://coveralls.io/r/rchampourlier/jira_cache?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jira_cache'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jira_cache

## Usage

Inside of `bin/console`:

```ruby
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
client = JiraCache::Client.new(
  domain: 'example.atlassian.net',
  username: 'username',
  password: 'password',
  logger: logger
)
JiraCache.sync_issue(client, 'PROJECT_KEY')
```

## Advanced use

### Getting notified on sync events

When you trigger a project sync with `JiraCache.sync_issues(<project_key>)`,
you can get notifications on every issue fetched by providing a notifier
instance to `JiraCache::Client`:

```
JiraCache::Client.set_notifier(MyNotifier.new)
```

Your notifier class must implement the `#publish(event_name, data)` method. See `JiraCache::Notifier` class for more details.

Your notifier's `#publish` method will get called synchronously on every issue fetch. Your responsible of making it being processed in the background if you don't want to slow down the fetching process. Also, beware that fetchs can be performed in multiple threads concurrently (by default 5, you can override it by setting `JiraCache::THREAD_POOL_SIZE`).

Currently notified events are:
- `fetched_issue`

## Contributing

1. Fork it ( https://github.com/rchampourlier/jira_cache/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Check the [code of conduct](CODE_OF_CONDUCT.md).
