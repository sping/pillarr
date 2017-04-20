# Pillarr

Pillarr provides an easy pluginable system to perform checks and log these into an json file.

## TODO:

- [ ] Tests
- [ ] Doc for adding plugins
- [ ] Doc for creating plugins

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pillarr', github: 'sping/pillarr'
```

And then execute:

    $ bundle
    $ rails g pillarr

## Add and configure plugins

You can add plugins by adding these into the initializer `config/initializers/pillarr.rb`.

TODO: document existing plugins

```
Pillarr.configure do |c|
  c.collectors  = <<-YAML
    my_plugin:
      timeout: 10
      username: user
      password: <%= ENV['MY_SECRET'] %>
  YAML
end
```

## Running

To collect the information from the plugins, you could:

1. Run the rake task `rake pillarr::collect`
2. Run the collector from your code by running `Pillarr::Collector.run`
3. Fetch and process the data hash manually:

```ruby
collector = Pillarr::Collector.new
collector.collect
results = collector.raw_data
```

## Cron

When using you want pillarr to run as a cronjob you could use the gem [whenever](https://github.com/javan/whenever)

Just add the following into your `config/schedule.rb`

```ruby
job_type :nice_rake, "cd :path && :environment_variable=:environment nice -n 12 :bundle_command rake :task --silent :output"

every 1.minute do
  nice_rake 'pillarr:collect'
end
```

This will run pillarr every minute with a `nice` value of `12`

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
