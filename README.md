# CountryRejector [![Build Status](https://travis-ci.org/Vodeclic/country_rejector.svg?branch=master)](https://github.com/Vodeclic/country_rejector) [![GitHub version](https://badge.fury.io/gh/Vodeclic%2Fcountry_rejector.svg)](https://badge.fury.io/gh/Vodeclic%2Fcountry_rejector) [![Coverage Status](https://coveralls.io/repos/Vodeclic/country_rejector/badge.svg?branch=master&service=github)](https://coveralls.io/github/Vodeclic/country_rejector?branch=master)

Rack middleware that ban any IP located in a ban list.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'country_rejector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install country_rejector

## Usage

Add this line in your application.rb
```ruby
config.middleware.use "CountryRejector::Middleware"
```

Create an initializer file (rack_reject_countries.rb)
```ruby
CountryRejector::Middleware.configure do |config|
  config.banned_list = ::Gaston.countries.banned # is an array that list all country codes that are banished
  # config.country_detector = lambda {|ip| ::TZInfo::detect_country(ip) } # is the processor that is executed to get the associated country code
  # config.env_ip_tag = "HTTP_X_REAL_IP" # is the key checked in ENV for the current ip
end
```
#

## Advice

Don't use this middleware in your test environnement! ( It's a bad idea ).
So add this line in your environments/test.rb for example:
```ruby
  config.middleware.delete ::CountryRejector::Middleware
```
## Testing the Gem
- Run the RSpec tests:
```system
bundle exec rspec
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Vodeclic/country_rejector.

## License
Copyright © 2016 Vodeclic SAS released under the  [MIT License](http://opensource.org/licenses/MIT).
