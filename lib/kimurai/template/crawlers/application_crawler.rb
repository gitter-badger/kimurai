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
    # Default headers for a session.
    # Format: hash. Example: { "some header" => "some value", "another header" => "another valye" }
    # works only for :mechanize and :poltergeist_phantomjs drivers (selenium don't allow to set custom headers).
    headers: {},

    # user_agent.
    # Format: string or lambda. Example of user agent string: "Some user agent".
    # If provided lambda, user_agent object will be called while creating session.
    # Works for all drivers
    # Note for chrome: keep in mind that chrome in native headless mode has headless user-agent,
    # so it's probably better to change it if you use chrome in headless mode
    user_agent: -> { USER_AGENTS.sample },

    # Default cookies for a session.
    # Format: array of hashes.
    # Format for a single cookie: { name: "cookie name", value: "cookie value", ... }
    # name, value, and domain are required.
    # Works for all drivers.
    # cookies: [],

    # Start url to visit for selenium to set default cookies. Suddenly selenium
    # don't allow to set cookies if current_url == "data:," (default url after session creation),
    # so we have to provide url to visit first, and than set cookies.
    # Selenium chrome allows to set cookies to any domain, it only needs to have any valid webpage
    # to be visited. For selenium firefox allowed to set cookies only for
    # current visited webpage's domain.
    selenium_url_to_set_cookies: "",

    # Proxy.
    # Format: string or lambda.
    # Format of proxy string: "protocol:ip:port:user:password"
    # `protocol` can be http or socks5. User and password are optional.
    # If provided lambda, proxy object will be called while creating session.
    # Works for all drivers, but keep in mind wht selenium (:selenium_firefox, :selenium_chrome)
    # doesn't support proxies with authorization. Also mechanize don't support socks proxy (only http)
    # proxy: -> { PROXIES.sample },

    # Tells not to use proxy for the list of domains or IP addresses.
    # Format: array of strings.
    # https://winaero.com/blog/override-proxy-settings-google-chrome/
    # Works only for :selenium_firefox and selenium_chrome.
    proxy_bypass_list: [],

    # Absolute path to the custom ssl cert. For example when you use proxy such as Crawlera,
    # or Mitmproxy with a self signed certs.
    # Works only for :poltergeist_phantomjs and :mechanize
    # ssl_cert_path: "path/to/cert",

    # If enabled, driver session will ignore any https errors. It also handy
    # when using proxy (for example crawlera with self signed cert in case of selenium)
    # or mitmproxy. Also, it will allow to download sites with expires https certs.
    # Works for all drivers.
    ignore_ssl_errors: true,

    # window resolution, works for all browsers
    window_size: [1366, 768],

    # If true, images will not be loaded.
    # Works for all browsers
    disable_images: true,

    # Headless mode for selenium browsers.
    # Possible values :native or :virtual_display (default is :native)
    # It's better to use native mode always, but some browsers (chrome)
    # has restricted possibilities in headless mode, for example chrome don't support
    # extentions in headless mode. In this case, good option is to use browser
    # in normal mode within virtual display (xvfb).
    # note: define env variable HEADLESS=false to run browser in normal mode (for debug)
    # Option works only for selenium browsers (and virtual_display only for linux environment)
    # Also, virtual_display mode can be usefull in case of chrome headless, some websites
    # can detect headless chrome (even with custom useragent). With virtual_display mode
    # chrome not detectable like in headless mode
    headless_mode: :native, # virtual_display

    # Session options
    session: {
      # automatically recreate session driver (browser) when one of conditions will be true.
      # Note: conditions checks before each session request
      recreate_driver_if: {
        # when requests count for session driver will reach this limit, driver will be recreated
        # requests_count: 80,
        # when session driver reach provided memory size, driver will be recreated
        memory_size: 350_000 # and more
      },
      before_request: {
        # works only for poltergeist and mechanize
        # `proxy` setting should be a lambda
        # change_proxy: true,
        # done # works only for poltergeist and mechanize
        # `user_agent` setting should be present and should be a lambda object
        change_user_agent: true,
        # works for all
        clear_cookies: true,
        # works for all # with some restrictions for selenium
        # clear_and_set_cookies: true,
        # Global option to set delay between requests.
        # Can be integer (5) or range (2..5). If range, delay number will be choosed randomly.
        # Note: you can set cusom delay for a custom request within `#request_to` method,
        # example: `request_to(:parse_listing, url: url, delay: 3..6)`,
        # or even directly while calling `session_instance#visit`, example: `browser.visit(url, delay: 3)`
        # delay: 3..6,
      }
    }
  }

  # Class methods .at_start and .at_stop will be called once
  # at starting and stopping. You can put in these methods some analytics, like
  # notification when crawler was started (inside .at_start method) and notification
  # when crawler was stopped (inside .at_stop method).
  # Use class method `.info` to determine status of the crawler. Possible values
  # of `info[:status]` is :running, :completed or :failed. There are additional helping methods
  # like `.running?`, `.completed?` and `.failed?`. For example in case of failed run,
  # you probably will want to send notification with error message, so inside
  # .at_stop, `status` will help you to determine the status of a run. Also, `.info`
  # contains a lot of information about crawlers run, like total count of requests, items,
  # pipelines errors, starting, start/stop time, etc.
  def self.at_start
    # puts "From crawler, before start"
  end

  def self.at_stop
    # puts "From crawler, after stop"
  end
end
