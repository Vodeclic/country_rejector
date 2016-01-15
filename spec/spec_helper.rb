$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'coveralls'
Coveralls.wear!

require 'country_rejector'
require 'rack'
require 'timeout'


def reset_configuration
  CountryRejector::Middleware.reset_configuration
end