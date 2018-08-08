require 'net/http'

Kimurai.configure do |config|
  config.retry_request_errors = [Net::ReadTimeout]
end
