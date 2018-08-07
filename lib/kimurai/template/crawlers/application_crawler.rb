class ApplicationCrawler < Kimurai::Base
  include ApplicationHelper

  # the name of the crawler (no spaces, and special symbols (., _ are allowed)) (should be uniq if not multilang.).
  # Don't set @name in the ApplicationCrawler class. It's a base crawler class for your
  # crawlers. All crawler classes with defined @name can be started within cli
  # by `$ kimurai start crawler_name`
  # You can simply use CLI generator `bundle exec kumurai generate crawler example.com --start_url https://example.com/`
  # to create start template of a crawler inherited from ApplicationCrawler
  # @name = "my_first_crawler"

  # Av. default drivers: :poltergeist_phantomjs, :selenium_firefox, :selenium_chrome, :mechanize.
  # Choose a default one if you want to configure it using @config (see below).
  # Or, you can configure a custom one in initializer and provide it here
  # (@config will be skipped for custom driver).
  # @driver declared here (ApplicationCrawler), all inherited crawlers will have
  # this driver by default.
  @driver = :poltergeist_phantomjs

  # Pipelines list, by order.
  # Default pipelines for all crawlers inherited from ApplicationCrawler.
  # Set different set of pipelines in the custom crawler if you need it to.
  @pipelines = [:validator, :converter, :saver]

  # default config for crawler.
  # Set config here in ApplicationCrawler as a base configuration for all crawlers.
  # If for some crawler you need to tweak these settings,
  # just write a custom @config there, and it will be DEEP merged with this one.
  @config = {
    # Custom headers, format: hash. Example: { "some header" => "some value", "another header" => "another value" }
    # Works only for :mechanize and :poltergeist_phantomjs drivers (Selenium don't allow to set/get headers)
    headers: {},

    # Custom user agent, format: string or lambda.
    # Use lambda if you want to rotate user agents before each run:
    # user_agent: -> { ARRAY_OF_USER_AGENTS.sample }
    # Works for all drivers
    user_agent: "Mozilla/5.0 Firefox/61.0",

    # Custom cookies, format: array of hashes.
    # Format for a single cookie: { name: "cookie name", value: "cookie value", domain: ".example.com" }
    # Works for all drivers
    cookies: [],

    # Selenium drivers only: start url to visit to set custom cookies. Selenium doesn't
    # allow to set custom cookies if current browser url is empty (start page).
    # To set cookies browser needs to visit some webpage first (and domain of this
    # webpage should be the same as the domain of cookie).
    selenium_url_to_set_cookies: "http://example.com/",

    # Proxy, format: string or lambda. Format of proxy string: "protocol:ip:port:user:password"
    # `protocol` can be http or socks5. User and password are optional.
    # Use lambda if you want to rotate proxies before each run:
    # proxy: -> { ARRAY_OF_PROXIES.sample }
    # Works for all drivers, but keep in mind that Selenium drivers doesn't support proxies
    # with authorization. Also, Mechanize driver doesn't support socks5 proxy format (only http)
    proxy: "http:3.4.5.6:3128:user:pass",

    # If enabled, browser will ignore any https errors. It's handy while using a proxy
    # with self-signed SSL cert (for example Crawlera or Mitmproxy)
    # Also, it will allow to visit webpages with expires SSL certificate.
    # Works for all drivers
    ignore_ssl_errors: true,

    # Custom window size, works for all drivers
    window_size: [1366, 768],

    # Skip images downloading if true, works for all drivers
    disable_images: true,

    # Selenium drivers only: headless mode, `:native` or `:virtual_display` (default is :native)
    # Although native mode has a better performance, virtual display mode
    # sometimes can be useful. For example, some websites can detect (and block)
    # headless chrome, so you can use virtual_display mode instead
    headless_mode: :native,

    # This option tells the browser not to use a proxy for the provided list of domains or IP addresses.
    # Format: array of strings. Works only for :selenium_firefox and selenium_chrome
    proxy_bypass_list: [],

    # Option to provide custom SSL certificate. Works only for :poltergeist_phantomjs and :mechanize
    ssl_cert_path: "path/to/ssl_cert",

    # Session (browser) options
    session: {
      recreate_driver_if: {
        # Restart browser if provided memory limit (in kilobytes) is exceeded (works for all drivers)
        memory_size: 350_000,

        # Restart browser if provided requests count is exceeded (works for all drivers)
        requests_count: 100
      },
      before_request: {
        # Change proxy before each request. The `proxy:` option above should be presented
        # and has lambda format. Works only for poltergeist and mechanize drivers
        # (selenium doesn't support proxy rotation).
        change_proxy: true,

        # Change user agent before each request. The `user_agent:` option above should be presented
        # and has lambda format. Works only for poltergeist and mechanize drivers
        # (selenium doesn't support to get/set headers).
        change_user_agent: true,

        # Clear all cookies before each request, works for all drivers
        clear_cookies: true,

        # If you want to clear all cookies + set custom cookies (`cookies:` option above should be presented)
        # use this option instead (works for all drivers)
        clear_and_set_cookies: true,

        # Global option to set delay between requests.
        # Delay can be `Integer`, `Float` or `Range` (`2..5`). In case of a range,
        # delay number will be chosen randomly for each request: `rand (2..5) # => 3`
        delay: 1..3,
      }
    }
  }


  def self.at_start
    # puts "From crawler, before start"
  end

  def self.at_stop
    # puts "From crawler, after stop"
  end
end
