class ApplicationCrawler < Kimurai::Base
  # the name of the crawler (no spaces, and special symbols (., _ are allowed)) (should be uniq if not multilang.).
  # Don't set @name in the ApplicationCrawler class. It's a base crawler class for your
  # crawlers. All crawler classes with defined @name can be started within cli
  # by `$ kimurai start crawler_name`
  # You can simply use CLI generator `bundle exec kumurai generate crawler example.com --site_url https://example.com/`
  # to create start template of a crawler inherited from ApplicationCrawler
  #@name = "fdsfs" #, multilangual: :en

  # Av. default drivers: :poltergeist_phantomjs, :selenium_firefox, :selenium_chrome, :mechanize.
  # Choose a default one if you want to configure it using default_settings.
  # Or, you can configure a custom one as an unitializer
  # (set the drivdr name other than default drivers),
  # and set it here (default_settings will be skipped for a custom driver).
  # by declaring @driver in ApplicationCrawler, all inherited crawlers will have
  # this driver by default.
  @driver = :mechanize

  # Pipelines list, by order.
  # Default pipelines for all crawlers inherited from ApplicationCrawler.
  # Set different order in the custom crawler if you need it to.
  @pipelines = [:validator, :converter, :saver]

  # default options for a default drivers.
  # Set default options here in ApplicationCrawler as a base default_options
  # for all of you crawlers. If for some crawler you need tweak these settings,
  # just write a custom @default_optins there, and it will be deep_merged with it.
  @default_options = {
    # Default headers for a session.
    # Format: hash. Example: { "some header" => "some value", "another header" => "another valye" }
    # works only for :mechanize and :poltergeist_phantomjs drivers (selenium don't allow to set custom headers).
    headers: {},
    # Default cookies for a session.
    # Format: array of hashes.
    # Format for a single cookie: { name: "cookie name", value: "cookie value", ... }
    # name, value, and domain are required.
    # Works for all drivers.
    cookies: [],
    # Start url to visit for selenium to set default cookies. Suddenly selenium
    # don't allow to set cookies if current_url == "data:," (default url after session creation),
    # so we have to provide url to visit first, and than set cookies.
    # Selenium chrome allows to set cookies to any domain, it only needs to have any valid webpage
    # to be visited. For selenium firefox allowed to set cookies only for
    # current visited webpage's domain.
    selenium_url_for_default_cookies: "",
    # List of user_agents.
    # Format: array of strings. Example of user agent string: "Some user agent".
    # If provided more than one, user agent will be choosed randomly for each new session.
    # Works for all drivers
    # Note for chrome: keep in mind what chrome in headless mode has headless user-agent,
    # so it's probably better to change it if you use chrome in headless mode
    user_agents_list: [],
    # List of proxies.
    # Format: array of hashes.
    # Format of a proxy hash:
    # { ip: "<PROXY_IP>", port: "<PROXY_PORT>", type: "<PROXY_PROTOCOL>", user: "<PROXY_USERNAME>", password: "<PROXY_PASS>" }
    # Type can be http or socks5. User and password are optional.
    # If provided more than one, proxy will be choosed randomly for each new session.
    # Works for all drivers, but keep in mind wht selenium (:selenium_firefox, :selenium_chrome)
    # doesn't support proxies with authorization.
    proxies_list: [],
    # Tells not to use proxy for the list of domains or IP addresses.
    # Format: array of strings.
    # https://winaero.com/blog/override-proxy-settings-google-chrome/
    # Works only for :selenium_firefox and selenium_chrome.
    proxy_bypass_list: [],
    # Absolute path to the custom ssl cert. For example when you use proxy such as Crawlera,
    # or Mitmproxy with a self signed certs.
    # Works only for :poltergeist_phantomjs and :mechanize
    ssl_cert_path: "",
    # If enabled, driver session will be ignored any https errors. It also handy
    # when using proxy (for example crawlera with self signed cert in case of selenium)
    # or mitmproxy. Also, it will allow to download sites with expires https certs.
    # Works for all drivers.
    ignore_ssl_errors: true,
    window_size: [1366, 768], # except of mechanize
    # If true, images will not be loaded.
    # Works for all real browsers (:selenium_firefox, :selenium_chrome, :poltergeist_phantomjs).
    disable_images: false,
    # Headless mode for selenium browsers.
    # Possible values :native or :virtual_display (default is :native)
    # It's better to use native mode always, but some browsers (chrome)
    # has restricted possibilities in headless mode, for example chrome don't support
    # extentions in headless mode. In this case, good option is to use browser
    # in normal mode within virtual display (xvfb).
    # note: define env variable HEADLESS=false to run browser in normal mode (for debug)
    # Option works only for selenium browsers (and virtual_display only for linux environment)
    headless_mode: :native, # virtual_display
    session_options: {
      recreate: {
        after_requests_count: 80,
        if_memory_more_than: 500_000 # done
      },
      before_request: {
        # works only for poltergeist and mechanize
        set_random_proxy: true,
        # done # works only for poltergeist and mechanize
        set_random_user_agent: true,
        # done # works for all
        clear_cookies: true,
        # works for all # with some restrictions for selenium
        clear_and_set_default_cookies: true,
        # Global option to set delay for a browser's session.
        # If present, browser will wait before process `visit` method to a url.
        # Can be integer (5) or range (2..5). If range, delay number will be choosen randomly.
        # Note: you can set cusom delay for a custom request within `#request_to` method,
        # example: `request_to(:parse_listing, url: url, delay: 3..6)`,
        # or even directly while calling `session_instance#visit`, example: `browser.visit(url, delay: 3)`
        # delay: 3..6,
      }
    },
    custom_options_for_driver: {
      # upd add custom extentions for browsers and js injection for phantom
      selenium_firefox: {
        # see all options here http://preferential.mozdev.org/preferences.html
        # http://kb.mozillazine.org/Firefox_:_FAQs_:_About:config_Entries
        profile_options: {},
        # You can use default firefox profile (set "default") or a custom one.
        # see how to create custom profile for firefox ...
        profile_name: "",
        # additional command line args for firefox
        args: []
      },

      selenium_chrome: {
        # not sure what the options
        profile_options: {},
        # same as arg --.
        # You can use default chrome profile or a custom one.
        # See how to create a custom profile and find out a path of chrome profiles: ...
        profile_path: "",
        # additional command line args for chrome
        # see all agrs here https://peter.sh/experiments/chromium-command-line-switches/
        args: []
      },

      poltergeist_phantomjs: {
        # same as arg --
        cookies_file_path: "",
        # additional command line args for phantomjs
        args: []
      },

      mechanize: {
        # you have to create jar file first will all cookies. To save current session to a
        # file, Use: `page.driver.browser.agent.cookie_jar.save("cookies.yaml", session: true)`.
        # Then you can provide a path to this file.
        # Also see http://www.virtuouscode.com/2016/06/17/preserving-session-with-mechanize/
        # https://gist.github.com/makevoid/4282237
        cookie_jar_file_path: ""
      }
    }
  }

  # Class methods .open_crawler and .close_crawler will be called once
  # at starting and stopping. You can put in these methods some analytics, like
  # notification when crawler was started (using .open_crawler) and notification
  # when crawler was stopped (using .close_crawler).
  # Use class method `.info` to determine the status of the crawler. Possible values
  # of `info[:status]` is :running, :completed or :failed. There are additional helping methods
  # like `.running?`, `.completed?` and `.failed?`. For example in case of failed run,
  # you probably will want to send notification with error message, so inside
  # .close_crawler, `status` will help you to determine the status of a run. Also, status
  # contains a lot of information about crawlers run, like total count of requests, items,
  # pipelines error, starting and stopping time, etc.
  def self.open_crawler
    # puts "From open crawler"
  end

  def self.close_crawler
    # puts "From close crawler"
  end
end
