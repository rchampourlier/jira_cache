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
JiraCache::Client.set_config(
  domain: 'example.atlassian.net',
  username: 'username',
  password: 'password',
  log_level: Logger::DEBUG
)
JiraCache.sync_issue('PROJECT_KEY')
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/jira_cache/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Check the [code of conduct](CODE_OF_CONDUCT.md).
