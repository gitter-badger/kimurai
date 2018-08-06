<div align="center">
  <a href="https://github.com/vfreefly/kimurai">
    <img width="312" height="200" src="https://hsto.org/webt/_v/mt/tp/_vmttpbpzbt-y2aook642d9wpz0.png">
  </a>

  <h1>Kimurai</h1>
</div>

Kimurai is a modern web scraping framework written in Ruby which **works out of box with headless chromium/firefox, phantomjs**, or simple HTTP requests and **allows to scrape and interact with javascript rendered websites.**

Kimurai based on well-known [Capybara](https://github.com/teamcapybara/capybara) and [Nokogiri](https://github.com/sparklemotion/nokogiri) gems, so you don't have to learn anything new. Lets see:

```ruby
# github_crawler.rb

require 'kimurai'
require 'kimurai/all'

class GithubCrawler < Kimurai::Base
  @name = "github_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://github.com/search?q=Ruby%20Web%20Scraping"]

  def parse(response, url:, data: {})
    response.xpath("//ul[@class='repo-list']/div//h3/a").each do |a|
      request_to :parse_repo_page, url: absolute_url(a[:href], base: url)
    end

    if next_page = response.at_xpath("//a[@class='next_page']")
      request_to :parse, url: absolute_url(next_page[:href], base: url)
    end
  end

  def parse_repo_page(response, url:, data: {})
    item = {}

    item[:owner] = response.xpath("//h1//a[@rel='author']").text
    item[:repo_name] = response.xpath("//h1/strong[@itemprop='name']/a").text
    item[:repo_url] = url
    item[:description] = response.xpath("//span[@itemprop='about']").text.squish
    item[:tags] = response.xpath("//div[@id='topics-list-container']/div/a").map { |a| a.text.squish }
    item[:watch_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Watch')]/a[2]").text.squish
    item[:star_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Star')]/a[2]").text.squish
    item[:fork_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Fork')]/a[2]").text.squish
    item[:last_commit] = response.xpath("//span[@itemprop='dateModified']/*").text

    save_to "results.json", item, format: :pretty_json
  end
end

GithubCrawler.start!
```

<details/>
  <summary>Run: <code>$ ruby github_crawler.rb</code></summary>

```
D, [2018-08-04 13:06:47 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session builder: driver gem required: selenium
D, [2018-08-04 13:06:47 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session builder: created session instance
I, [2018-08-04 13:06:47 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: started get request to: https://github.com/search?q=Ruby%20Web%20Scraping
D, [2018-08-04 13:06:47 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session builder: enabled native headless mode for selenium_chrome
D, [2018-08-04 13:06:47 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session builder: created driver instance (selenium_chrome)
I, [2018-08-04 13:06:48 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: a new session driver has been created: driver name: selenium_chrome, pid: 24734, port: 9515
I, [2018-08-04 13:07:00 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: finished get request to: https://github.com/search?q=Ruby%20Web%20Scraping
I, [2018-08-04 13:07:00 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Stats visits: requests: 1, responses: 1
D, [2018-08-04 13:07:00 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session: current_memory: 163832
I, [2018-08-04 13:07:01 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: started get request to: https://github.com/lorien/awesome-web-scraping
I, [2018-08-04 13:07:05 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: finished get request to: https://github.com/lorien/awesome-web-scraping
I, [2018-08-04 13:07:05 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Stats visits: requests: 2, responses: 2
D, [2018-08-04 13:07:05 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session: current_memory: 270462
I, [2018-08-04 13:07:05 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: started get request to: https://github.com/jaimeiniesta/metainspector
...
I, [2018-08-04 13:09:23 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: started get request to: https://github.com/preston/idclight
I, [2018-08-04 13:09:23 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Session: finished get request to: https://github.com/preston/idclight
I, [2018-08-04 13:09:23 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Stats visits: requests: 137, responses: 137
D, [2018-08-04 13:09:23 +0400#24700] [Main: 47383751083520] DEBUG -- github_crawler: Session: current_memory: 280797
I, [2018-08-04 13:09:23 +0400#24700] [Main: 47383751083520]  INFO -- github_crawler: Crawler: stopped: {:crawler_name=>"github_crawler", :status=>:completed, :environment=>"development", :start_time=>2018-08-04 13:06:47 +0400, :stop_time=>2018-08-04 13:09:23 +0400, :running_time=>"2m, 36s", :session_id=>nil, :visits=>{:requests=>137, :responses=>137, :requests_errors=>{}}, :error=>nil, :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>24700}}
```
</details>


<details/>
  <summary>results.json</summary>

```json
[
  {
    "owner": "lorien",
    "repo_name": "awesome-web-scraping",
    "repo_url": "https://github.com/lorien/awesome-web-scraping",
    "description": "List of libraries, tools and APIs for web scraping and data processing.",
    "tags": [
      "awesome",
      "awesome-list",
      "web-scraping",
      "data-processing",
      "python",
      "javascript",
      "php",
      "ruby"
    ],
    "watch_count": "161",
    "star_count": "2,400",
    "fork_count": "348",
    "last_commit": "19 days ago",
    "position": 1
  },
  ...
  {
    "owner": "preston",
    "repo_name": "idclight",
    "repo_url": "https://github.com/preston/idclight",
    "description": "A Ruby gem for accessing the freely available IDClight (IDConverter Light) web service, which convert between different types of gene IDs such as Hugo and Entrez. Queries are screen scraped from http://idclight.bioinfo.cnio.es.",
    "tags": [

    ],
    "watch_count": "6",
    "star_count": "1",
    "fork_count": "0",
    "last_commit": "on Apr 12, 2012",
    "position": 124
  }
]
```
</details>

---

Okay, that was easy. How about javascript rendered websites with dynamic HTML? Lets scrape a page with infinite scroll:

```ruby
# infinite_scroll_crawler.rb

require 'kimurai'
require 'kimurai/all'

class InfiniteScrollCrawler < Kimurai::Base
  @name = "infinite_scroll_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://infinite-scroll.com/demo/full-page/"]

  def parse(response, url:, data: {})
    posts_headers_path = "//article/h2"
    count = response.xpath(posts_headers_path).count

    loop do
      browser.execute_script("window.scrollBy(0,10000)") ; sleep 2
      response = browser.current_response

      new_count = response.xpath(posts_headers_path).count
      if count == new_count
        logger.info "> Pagination is done" and break
      else
        count = new_count
        logger.info "> Continue scrolling, current count is #{count}..."
      end
    end

    posts_headers = response.xpath(posts_headers_path).map(&:text)
    logger.info "> All posts from page: #{posts_headers.join('; ')}"
  end
end

InfiniteScrollCrawler.start!
```

<details/>
  <summary>Run: <code>$ ruby infinite_scroll_crawler.rb</code></summary>

```
D, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160] DEBUG -- infinite_scroll_crawler: Session builder: driver gem required: selenium
D, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160] DEBUG -- infinite_scroll_crawler: Session builder: created session instance
I, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: Session: started get request to: https://infinite-scroll.com/demo/full-page/
D, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160] DEBUG -- infinite_scroll_crawler: Session builder: enabled native headless mode for selenium_chrome
D, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160] DEBUG -- infinite_scroll_crawler: Session builder: created driver instance (selenium_chrome)
I, [2018-08-04 17:54:14 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: Session: a new session driver has been created: driver name: selenium_chrome, pid: 29342, port: 9515
I, [2018-08-04 17:54:18 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: Session: finished get request to: https://infinite-scroll.com/demo/full-page/
I, [2018-08-04 17:54:18 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: Stats visits: requests: 1, responses: 1
D, [2018-08-04 17:54:18 +0400#29308] [Main: 47115312711160] DEBUG -- infinite_scroll_crawler: Session: current_memory: 145957
I, [2018-08-04 17:54:21 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Continue scrolling, current count is 5...
I, [2018-08-04 17:54:28 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Continue scrolling, current count is 9...
I, [2018-08-04 17:54:34 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Continue scrolling, current count is 11...
I, [2018-08-04 17:54:40 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Continue scrolling, current count is 13...
I, [2018-08-04 17:54:43 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Continue scrolling, current count is 15...
I, [2018-08-04 17:54:45 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > Pagination is done
I, [2018-08-04 17:54:45 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: > All posts from page: 1a - Infinite Scroll full page demo; 1b - RGB Schemes logo in Computer Arts; 2a - RGB Schemes logo; 2b - Masonry gets horizontalOrder; 2c - Every vector 2016; 3a - Logo Pizza delivered; 3b - Some CodePens; 3c - 365daysofmusic.com; 3d - Holograms; 4a - Huebee: 1-click color picker; 4b - Word is Flickity is good; Flickity v2 released: groupCells, adaptiveHeight, parallax; New tech gets chatter; Isotope v3 released: stagger in, IE8 out; Packery v2 released
I, [2018-08-04 17:54:45 +0400#29308] [Main: 47115312711160]  INFO -- infinite_scroll_crawler: Crawler: stopped: {:crawler_name=>"infinite_scroll_crawler", :status=>:completed, :environment=>"development", :start_time=>2018-08-04 17:54:14 +0400, :stop_time=>2018-08-04 17:54:45 +0400, :running_time=>"31s", :session_id=>nil, :visits=>{:requests=>1, :responses=>1, :requests_errors=>{}}, :error=>nil, :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>29308}}
```
</details>

---

## Features

* Scrape javascript rendered websites
* Supported drivers: [Headless Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome), [Headless Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode), [PhantomJS](https://github.com/ariya/phantomjs) and  HTTP requests ([mechanize](https://github.com/sparklemotion/mechanize) gem)
* Write crawler code once, and use it with any supported driver later. You can even switch between drivers on the fly
* All the power of [Capybara](https://github.com/teamcapybara/capybara): use methods like `click_on`, `fill_in`, `select`, `choose`, `set`, `go_back`, etc. to interact with web pages
* Rich configuration: **set default headers, cookies, delay between requests, enable proxy/user-agents rotation**. Auto retry if a request was failed
* Settings and crawlers inheritation
* **Two modes:** write a single file for simple crawler, or generate Scrapy like **project with pipelines, configuration, etc.**
* Automatically restart browser when reaching memory limit **(memory control)** or requests limit (set limit in the crawler config)
* Parallel crawling using simple method: `in_parallel(:callback_name, threads_count, urls: urls)`
* Convenient development mode with console, colorized logger and debugger ([Pry](https://github.com/pry/pry), [Byebug](https://github.com/deivid-rodriguez/byebug)). Add `HEADLESS=false` before command to quickly switch between headless (default) and normal (visible) mode for Selenium-like drivers (Chrome, Firefox).
* Full stats for each crawler run: requests/items count + web dashboard
* Auto environment setup (for ubuntu 16.04-18.04) and deploy using commands `kimurai setup` and `kimurai deploy` ([Ansible](https://github.com/ansible/ansible) under the hood)
* Easily schedule crawlers within cron using [Whenever](https://github.com/javan/whenever) (no need to know cron syntax)
* Command-line runner to run all project crawlers one by one or in parallel
* Built-in helpers to make scraping easy, like `save_to` (save items to JSON, JSON lines, CSV or YAML formats) or `absolute_url/normalize_url`
* `at_start` and `at_stop` callbacks which allows to make something useful (like sending notification) before crawler started or after crawler has been stopped (available full run info: requests/items count, total time, etc)

## Installation

Kimurai requires Ruby version `>= 2.5.0`. Supported platforms: `Linux` and `Mac OS X`.

1) If your system doesn't have appropriate Ruby version, install it:

<details/>
  <summary>Ubuntu 18.04</summary>

```bash
# Install required packages for ruby-build
sudo apt update
sudo apt install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libreadline6-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev

# Install rbenv and ruby-build
cd && git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

# Install latest Ruby
rbenv install 2.5.1
rbenv global 2.5.1

gem install bundler
```
</details>

<details/>
  <summary>Mac OS X</summary>

```bash
# Install homebrew if you don't have it https://brew.sh/
# Install rbenv and ruby-build:
brew install rbenv ruby-build

# Add rbenv to bash so that it loads every time you open a terminal
echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bash_profile
source ~/.bash_profile

# Install latest Ruby
rbenv install 2.5.1
rbenv global 2.5.1

gem install bundler
```
</details>

2) Install Kimurai gem: `$ gem install kimurai`

3) Install browsers with webdrivers:

<details/>
  <summary>Ubuntu 18.04</summary>

Note: for Ubuntu 16.04-18.04 there is available automatic installation using `setup` command:
```bash
$ kimurai setup localhost --local --ask-sudo
```
It works using [Ansible](https://github.com/ansible/ansible) so you need to install it first: `$ sudo apt install ansible`. You can check using playbooks [here](lib/kimurai/automation).

If you chose automatic installation, you can skip following and go to "Getting To Know" part. In case if you want to install everything manually:

```bash
# Install basic tools
sudo apt install -q -y unzip wget tar openssl

# Install xvfb (for virtual_display headless mode, in additional to native)
sudo apt install -q -y xvfb

# Install chromium-browser and firefox
sudo apt install -q -y chromium-browser firefox

# Instal chromedriver (2.39 version)
# All versions located here https://sites.google.com/a/chromium.org/chromedriver/downloads
cd /tmp && wget https://chromedriver.storage.googleapis.com/2.39/chromedriver_linux64.zip
sudo unzip chromedriver_linux64.zip -d /usr/local/bin
rm -f chromedriver_linux64.zip

# Install geckodriver (0.21.0 version)
# All versions located here https://github.com/mozilla/geckodriver/releases/
cd /tmp && wget https://github.com/mozilla/geckodriver/releases/download/v0.21.0/geckodriver-v0.21.0-linux64.tar.gz
sudo tar -xvzf geckodriver-v0.21.0-linux64.tar.gz -C /usr/local/bin
rm -f geckodriver-v0.21.0-linux64.tar.gz

# Install PhantomJS (2.1.1)
# All versions located here http://phantomjs.org/download.html
sudo apt install -q -y chrpath libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev
cd /tmp && wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar -xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2
sudo mv phantomjs-2.1.1-linux-x86_64 /usr/local/lib
sudo ln -s /usr/local/lib/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin
rm -f phantomjs-2.1.1-linux-x86_64.tar.bz2
```

</details>

<details/>
  <summary>Mac OS X</summary>

```bash
# Install chrome and firefox
brew cask install google-chrome firefox

# Install chromedriver (latest)
brew cask install chromedriver

# Install geckodriver (latest)
brew install geckodriver

# Install PhantomJS (latest)
brew install phantomjs
```
</details><br>

Also, you'll probably want to save scraped items to the database (using [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord), [Sequel](https://github.com/jeremyevans/sequel) or [MongoDB Ruby Driver](https://github.com/mongodb/mongo-ruby-driver)/[Mongoid](https://github.com/mongodb/mongoid)). For this you need to install database clients/servers:

<details/>
  <summary>Ubuntu 18.04</summary>

SQlite: `$ sudo apt -q -y install libsqlite3-dev sqlite3`.

If you want to connect to a remote database, you don't need database server on local machine, only client:
```bash
# Install MySQL client
sudo apt -q -y install mysql-client libmysqlclient-dev

# Install Postgres client
sudo apt install -q -y postgresql-client libpq-dev

# Install MongoDB client
sudo apt install -q -y mongodb-clients
```

But if you want to save items to a local database, server required as well:
```bash
# Install MySQL client and server
sudo apt -q -y install mysql-server mysql-client libmysqlclient-dev

# Install  Postgres client and server
sudo apt install -q -y postgresql postgresql-contrib libpq-dev

# Install MongoDB client and server
# version 4.0 (check here https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/)
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
# for 16.04:
# echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
# for 18.04:
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt update
sudo apt install -q -y mongodb-org
sudo service mongod start
```
</details>

<details/>
  <summary>Mac OS X</summary>

SQlite: `$ brew install sqlite3`

```bash
# Install MySQL client and server
brew install mysql
# Start server if you need it: brew services start mysql

# Install Postgres client and server
brew install postgresql
# Start server if you need it: brew services start postgresql

# Install MongoDB client and server
brew install mongodb
# Start server if you need it: brew services start mongodb
```
</details>


## Getting To Know
### Minimum required crawler structure

```ruby
require 'kimurai'
require 'kimurai/all'

class SimpleCrawler < Kimurai::Base
  @name = "simple_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def parse(response, url:, data: {})
  end
end

SimpleCrawler.start!
```

Where:
* class variable `@name` it's a name of crawler. You can omit name if use single file crawler
* `@driver` driver for crawler
* `@start_urls` array of start urls to process one by one inside `parse` method
* Method `parse` is the starting method, should always present in crawler class

Each instance crawler method which you want to access from `request_to` should take following arguments:
* `response` is [Nokogiri::HTML::Document](https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/HTML/Document) object. Contains parsed HTML code from [Capybara::Session](https://www.rubydoc.info/github/jnicklas/capybara/Capybara/Session) [#body method](https://www.rubydoc.info/github/jnicklas/capybara/Capybara%2FSession:body) of currently processing url. **You can query `response` using [XPath or CSS selectors.](https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Searchable)**
* `url` current processing url (string)
* `data` hash which can contain something useful. It uses to pass data between requests.

<details/>
  <summary><strong>Example how to use <code>data</code></strong></summary>

Imagine that there is a product page which doesn't contain product category. Category name present only on category page with pagination. This is the case where we can use `data` to pass category name from `parse` to `parse_product` method:

```ruby
class ProductsCrawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example-shop.com/example-product-category"]

  def parse(response, url:, data: {})
    category_name = response.xpath("//path/to/category/name").text

    response.xpath("//path/to/products/urls").each do |product_url|
      # merge category_name with current data hash and pass it next to parse_product method
      request_to(:parse_product, url: product_url[:href], data: data.merge(category_name: category_name))
    end

    # ...
  end

  def parse_product(response, url:, data: {})
    item = {}
    # assign item's category_name from data[:category_name]
    item[:category_name] = data[:category_name]

    # ...
  end
end

```
</details>

### Available drivers

Kimurai has support for following drivers and mostly can switch between them without need to rewrite any code:

* `:mechanize` - [pure Ruby fake http browser](https://github.com/sparklemotion/mechanize). Mechanize can't render javascript and don't know what DOM is it. It only can parse original HTML code of a page. Because of it, mechanize much faster, takes much less memory and in general much more stable than any real browser. Use mechanize if you can do it, and the website doesn't use javascript to render any meaningful parts of its structure. Still, because mechanize trying to mimic a real browser, it supports almost all Capybara's [methods to interact with a web page](http://cheatrags.com/capybara) (filling forms, clicking buttons, checkboxes, etc).
* `:poltergeist_phantomjs` - [PhantomJS headless browser](https://github.com/ariya/phantomjs), can render javascript. In general, PhantomJS still faster than Headless Chrome (and headless firefox). PhantomJS has memory leakage, but Kimurai has memory control feature so you shouldn't consider it as a problem. Also, some websites can recognize PhantomJS and block access to them. Like mechanize (and unlike selenium drivers) `:poltergeist_phantomjs` can freely rotate proxies and change headers _on the fly_ (See Config section).
* `:selenium_chrome` Chrome in headless mode driven by selenium. Modern headless browser solution with proper javascript rendering.
* `:selenium_firefox` Firefox in headless mode driven by selenium. Usually takes more memory than other drivers, but sometimes can be useful.

Tip: add `HEADLESS=false` env variable before command (`$ HEADLESS=false ruby crawler.rb`) to run browser in normal (not headless) mode and see it's window (only for selenium-like drivers).

### `browser` object

From any crawler instance method there is available `browser` object, which is [Capybara::Session](https://www.rubydoc.info/github/jnicklas/capybara/Capybara/Session) instance and uses to process requests. Usually you don't need to touch it directly, because there is `response` (see above) which contains page response after it was loaded.

But if you need to interact with a page (like filling form fields, clicking elements, checkboxes, etc) `browser` is ready for you:

```ruby
class GoogleCrawler < Kimurai::Base
  @name = "google_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://www.google.com/"]

  def parse(response, url:, data: {})
    browser.fill_in "q", with: "Kimurai web scraping framework"
    browser.click_button "Google Search"

    # Update response to current response after interaction with browser
    response = browser.current_response

    # collect results
    results = response.xpath("//div[@class='g']//h3/a").map do |a|
      { title: a.text, url: a[:href] }
    end

    # ...
  end
end
```

Check out **Capybara cheat sheets** where you can see all available methods **to interact with browser**:
* [UI Testing with RSpec and Capybara [cheat sheet]](http://cheatrags.com/capybara) - cheatrags.com
* [Capybara Cheatsheet PDF](https://thoughtbot.com/upcase/test-driven-rails-resources/capybara.pdf) - thoughtbot.com

### `request_to` method

For making requests to a particular method there is `request_to`. It requires minimum two arguments: `:method_name` and `url:`. An optional argument is `data:` (see above what for is it). Example:

```ruby
class Crawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def parse(response, url:, data: {})
    request_to :parse_product, url: "https://example.com/some_product"
  end

  def parse_product(response, url:, data: {})
    puts "from page https://example.com/some_product !"
  end
end
```

Under the hood `request_to` simply call [#visit](https://www.rubydoc.info/github/jnicklas/capybara/Capybara%2FSession:visit) (`browser.visit(url)`) and then required method with arguments:

<details/>
  <summary>request_to</summary>

```ruby
def request_to(handler, url:, data: {})
  request_data = { url: url, data: data }

  browser.visit(url)
  public_send(handler, browser.current_response, request_data)
end
```
</details><br>

`request_to` just makes things simpler, and without it we could do something like:

<details/>
  <summary>Check the code</summary>

```ruby
class Crawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def parse(response, url:, data: {})
    url_to_process = "https://example.com/some_product"

    browser.visit(url_to_process)
    parse_product(browser.current_response, url: url_to_process)
  end

  def parse_product(response, url:, data: {})
    puts "from page https://example.com/some_product !"
  end
end
```
</details>

### `save_to` helper

Sometimes all that you need is to simply save scraped data to a file format, like JSON or CSV. You can use `save_to` for it:

```ruby
class ProductsCrawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example-shop.com/"]

  # ...

  def parse_product(response, url:, data: {})
    item = {}

    item[:title] = response.xpath("//title/path").text
    item[:description] = response.xpath("//desc/path").text.squish
    item[:price] = response.xpath("//price/path").text[/\d+/]&.to_f

    # add each new item to `scraped_products.json` file
    save_to "scraped_products.json", item, format: :json
  end
end
```

Supported formats:
* `:yaml` YAML
* `:json` JSON
* `:pretty_json` "pretty" JSON (`JSON.pretty_generate`)
* `:jsonlines` [JSON Lines](http://jsonlines.org/)
* `:csv` CSV

Note: `save_to` requires data (item to save) to be a `Hash`.

By default `save_to` add position key to an item hash. You can disable it with `position: false`: `save_to "scraped_products.json", item, format: :json, position: false`.

**How helper works:**

Until crawler stops, each new item will be appended to a file. At the next run, helper will clear the content of a file first, and then start again appending items to it.

### Skip duplicates, `unique?` helper

It's pretty common when websites have duplicated pages. For example when an e-commerce shop has the same products in different categories. To skip duplicates, there is `unique?` helper:

```ruby
class ProductsCrawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example-shop.com/"]

  def parse(response, url:, data: {})
    response.xpath("//categories/path").each do |category|
      request_to :parse_category, url: category[:href]
    end
  end

  # check products for uniqueness using product url inside of parse_category
  def parse_category(response, url:, data: {})
    response.xpath("//products/path").each do |product|
      # skip url if it's not unique
      next unless unique?(product_url: product[:href])
      # otherwise process it
      request_to :parse_product, url: product[:href]
    end
  end

  # or/and check products for uniqueness using product stock number inside of parse_product
  def parse_product(response, url:, data: {})
    item = {}
    item[:stock_number] = response.xpath("//product/stock_number/path").text.strip.upcase
    # don't save product and return from method if there is already saved item with same stock_number
    return unless unique?(stock_number: item[:stock_number])

    # ...
    save_to "results.json", item, format: :json
  end
end
```

`unique?` helper works pretty simple:

```ruby
# check string "http://example.com" in scope `url` for a first time:
unique?(url: "http://example.com")
# => true

# try again:
unique?(url: "http://example.com")
# => false
```

To check something for uniqueness, you need to provide a scope:

```ruby
# `product_url` scope
unique?(product_url: "http://example.com/product_1")

# `id` scope
unique?(id: 324234232)

# `custom` scope
unique?(custom: "Lorem Ipsum")
```

### `at_start` and `at_stop` callbacks

You can define `.at_start` and `.at_stop` callbacks (class methods) to perform some action before crawler started or after crawler has been stopped:

```ruby
require 'kimurai'
require 'kimurai/all'

class Crawler < Kimurai::Base
  @name = "example_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def self.at_start
    logger.info "> Starting..."
  end

  def self.at_stop
    logger.info "> Stopped!"
  end

  def parse(response, url:, data: {})
    logger.info "> Scraping..."
  end
end

Crawler.start!
```

<details/>
  <summary>Output</summary>

```
I, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: > Starting...
D, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800] DEBUG -- example_crawler: Session builder: driver gem required: selenium
D, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800] DEBUG -- example_crawler: Session builder: created session instance
I, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: Session: started get request to: https://example.com/
D, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800] DEBUG -- example_crawler: Session builder: enabled native headless mode for selenium_chrome
D, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800] DEBUG -- example_crawler: Session builder: created driver instance (selenium_chrome)
I, [2018-08-05 23:14:55 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: Session: a new session driver has been created: driver name: selenium_chrome, pid: 15840, port: 9515
I, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: Session: finished get request to: https://example.com/
I, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: Stats visits: requests: 1, responses: 1
D, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800] DEBUG -- example_crawler: Session: current_memory: 129448
I, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: > Scraping...
I, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: Crawler: stopped: {:crawler_name=>"example_crawler", :status=>:completed, :environment=>"development", :start_time=>2018-08-05 23:14:55 +0400, :stop_time=>2018-08-05 23:14:56 +0400, :running_time=>"1s", :session_id=>nil, :visits=>{:requests=>1, :responses=>1, :requests_errors=>{}}, :error=>nil, :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>15800}}
I, [2018-08-05 23:14:56 +0400#15800] [Main: 47044281271800]  INFO -- example_crawler: > Stopped!

```
</details><br>

Inside `at_start` and `at_stop` class methods there is available `run_info` method which contains useful information about crawler state:

```ruby
    11: def self.at_start
 => 12:   binding.pry
    13: end

[1] pry(example_crawler)> run_info
=> {
  :crawler_name=>"example_crawler",
  :status=>:running,
  :environment=>"development",
  :start_time=>2018-08-05 23:32:00 +0400,
  :stop_time=>nil,
  :running_time=>nil,
  :session_id=>nil,
  :visits=>{:requests=>0, :responses=>0, :requests_errors=>{}},
  :error=>nil,
  :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>20814}
}

```

Inside `at_stop`, `run_info` will be updated:

```ruby
    15: def self.at_stop
 => 16:   binding.pry
    17: end

[1] pry(example_crawler)> run_info
=> {
  :crawler_name=>"example_crawler",
  :status=>:completed,
  :environment=>"development",
  :start_time=>2018-08-05 23:32:00 +0400,
  :stop_time=>2018-08-05 23:32:06 +0400,
  :running_time=>6.214,
  :session_id=>nil,
  :visits=>{:requests=>1, :responses=>1, :requests_errors=>{}},
  :error=>nil,
  :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>20814}
}
```

`run_info[:status]` helps to determine if crawler was finished successfully or failed (possible values: `:completed`, `:failed`):

```ruby
class Crawler < Kimurai::Base
  @name = "example_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def self.at_stop
    puts ">>> run info: #{run_info}"
  end

  def parse(response, url:, data: {})
    logger.info "> Scraping..."
    # Let's try to strip nil:
    nil.strip
  end
end
```

<details/>
  <summary>Output</summary>

```
D, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320] DEBUG -- example_crawler: Session builder: driver gem required: selenium
D, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320] DEBUG -- example_crawler: Session builder: created session instance
I, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320]  INFO -- example_crawler: Session: started get request to: https://example.com/
D, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320] DEBUG -- example_crawler: Session builder: enabled native headless mode for selenium_chrome
D, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320] DEBUG -- example_crawler: Session builder: created driver instance (selenium_chrome)
I, [2018-08-05 23:52:54 +0400#26484] [Main: 47111535224320]  INFO -- example_crawler: Session: a new session driver has been created: driver name: selenium_chrome, pid: 26516, port: 9515
I, [2018-08-05 23:52:55 +0400#26484] [Main: 47111535224320]  INFO -- example_crawler: Session: finished get request to: https://example.com/
I, [2018-08-05 23:52:55 +0400#26484] [Main: 47111535224320]  INFO -- example_crawler: Stats visits: requests: 1, responses: 1
D, [2018-08-05 23:52:55 +0400#26484] [Main: 47111535224320] DEBUG -- example_crawler: Session: current_memory: 129015
I, [2018-08-05 23:52:55 +0400#26484] [Main: 47111535224320]  INFO -- example_crawler: > Scraping...
F, [2018-08-05 23:52:55 +0400#26484] [Main: 47111535224320] FATAL -- example_crawler: Crawler: stopped: {:crawler_name=>"example_crawler", :status=>:failed, :environment=>"development", :start_time=>2018-08-05 23:52:54 +0400, :stop_time=>2018-08-05 23:52:55 +0400, :running_time=>"1s", :session_id=>nil, :visits=>{:requests=>1, :responses=>1, :requests_errors=>{}}, :error=>"#<NoMethodError: undefined method `strip' for nil:NilClass>", :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>26484}}

>>> run info: {:crawler_name=>"example_crawler", :status=>:failed, :environment=>"development", :start_time=>2018-08-05 23:52:54 +0400, :stop_time=>2018-08-05 23:52:55 +0400, :running_time=>1.445, :session_id=>nil, :visits=>{:requests=>1, :responses=>1, :requests_errors=>{}}, :error=>"#<NoMethodError: undefined method `strip' for nil:NilClass>", :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>26484}}

Traceback (most recent call last):
        6: from crawler.rb:22:in `<main>'
        5: from /home/victor/code/kimurai/lib/kimurai/base.rb:135:in `start!'
        4: from /home/victor/code/kimurai/lib/kimurai/base.rb:135:in `each'
        3: from /home/victor/code/kimurai/lib/kimurai/base.rb:136:in `block in start!'
        2: from /home/victor/code/kimurai/lib/kimurai/base.rb:178:in `request_to'
        1: from /home/victor/code/kimurai/lib/kimurai/base.rb:178:in `public_send'
crawler.rb:18:in `parse': undefined method `strip' for nil:NilClass (NoMethodError)
```
</details><br>

**Usage example:** if crawler finished successfully, send JSON file with scraped items to a remote FTP location, otherwise (if crawler failed), skip incompleted results and send email/notification to slack about it:

<details/>
  <summary>Show example</summary>

Also you can use additional methods `completed?` or `failed?`

```ruby
class Crawler < Kimurai::Base
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def self.at_stop
    if completed?
      send_file_to_ftp("results.json")
    else
      send_error_notification(run_info[:error])
    end
  end

  def self.send_file_to_ftp(file_path)
    # ...
  end

  def self.send_error_notification(error)
    # ...
  end

  # ...

  def parse_item(response, url:, data: {})
    item = {}

    # ...

    save_to "results.json", item, format: :json
  end
end
```
</details>

### Parallel crawling using `in_parallel`

Kimurai can process web pages concurrently in one single line: `in_parallel(:parse_product, 3, urls: urls)`, where `:parse_product` is a method to process, `3` is count of threads and `urls:` is array of urls to crawl.

```ruby
# amazon_crawler.rb

require 'kimurai'
require 'kimurai/all'

class AmazonCrawler < Kimurai::Base
  @name = "amazon_crawler"
  @driver = :mechanize
  @start_urls = ["https://www.amazon.com/"]

  def parse(response, url:, data: {})
    browser.fill_in "field-keywords", with: "Web Scraping Books"
    browser.click_on "Go"

    # walk through pagination and collect products urls:
    urls = []
    loop do
      response = browser.current_response
      response.xpath("//li//a[contains(@class, 's-access-detail-page')]").each do |a|
        urls << a[:href].sub(/ref=.+/, "")
      end

      browser.find(:xpath, "//a[@id='pagnNextLink']", wait: 1).click rescue break
    end

    # process all collected urls concurrently within 3 threads:
    in_parallel(:parse_book_page, 3, urls: urls)
  end

  def parse_book_page(response, url:, data: {})
    item = {}

    item[:title] = response.xpath("//h1/span[@id]").text.squish
    item[:url] = url
    item[:price] = response.xpath("(//span[contains(@class, 'a-color-price')])[1]").text.squish.presence
    item[:publisher] = response.xpath("//h2[text()='Product details']/following::b[text()='Publisher:']/following-sibling::text()[1]").text.squish.presence

    save_to "books.json", item, format: :pretty_json
  end
end

AmazonCrawler.start!
```

<details/>
  <summary>Run: <code>$ ruby amazon_crawler.rb</code></summary>

```
D, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960] DEBUG -- amazon_crawler: Session builder: driver gem required: mechanize
D, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960] DEBUG -- amazon_crawler: Session builder: created session instance
I, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/
D, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960] DEBUG -- amazon_crawler: Session builder: created driver instance (mechanize)
D, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960] DEBUG -- amazon_crawler: Session: can't define driver_pid and driver_port for mechanize, not supported
I, [2018-08-06 12:21:48 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Session: a new session driver has been created: driver name: mechanize, pid: , port:
I, [2018-08-06 12:21:54 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Session: finished get request to: https://www.amazon.com/
I, [2018-08-06 12:21:54 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Stats visits: requests: 1, responses: 1

I, [2018-08-06 12:21:58 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Crawler: in_parallel: starting processing 53 urls within 3 threads
D, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460] DEBUG -- amazon_crawler: Session builder: driver gem required: mechanize
D, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460] DEBUG -- amazon_crawler: Session builder: created session instance
I, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491985577/
D, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460] DEBUG -- amazon_crawler: Session builder: created driver instance (mechanize)
D, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460] DEBUG -- amazon_crawler: Session: can't define driver_pid and driver_port for mechanize, not supported
I, [2018-08-06 12:21:58 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Session: a new session driver has been created: driver name: mechanize, pid: , port:
D, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660] DEBUG -- amazon_crawler: Session builder: driver gem required: mechanize
D, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660] DEBUG -- amazon_crawler: Session builder: created session instance
I, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/Python-Web-Scraping-Cookbook-scraping/dp/1787285219/
D, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660] DEBUG -- amazon_crawler: Session builder: created driver instance (mechanize)
D, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660] DEBUG -- amazon_crawler: Session: can't define driver_pid and driver_port for mechanize, not supported
I, [2018-08-06 12:21:59 +0400#1686] [Child: 47180448535660]  INFO -- amazon_crawler: Session: a new session driver has been created: driver name: mechanize, pid: , port:
D, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660] DEBUG -- amazon_crawler: Session builder: driver gem required: mechanize
D, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660] DEBUG -- amazon_crawler: Session builder: created session instance
I, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/Practical-Web-Scraping-Data-Science/dp/1484235819/
D, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660] DEBUG -- amazon_crawler: Session builder: created driver instance (mechanize)
D, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660] DEBUG -- amazon_crawler: Session: can't define driver_pid and driver_port for mechanize, not supported
I, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448251660]  INFO -- amazon_crawler: Session: a new session driver has been created: driver name: mechanize, pid: , port:
I, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Session: finished get request to: https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491985577/
I, [2018-08-06 12:22:00 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Stats visits: requests: 4, responses: 2
I, [2018-08-06 12:22:01 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491910291/
I, [2018-08-06 12:22:01 +0400#1686] [Child: 47180448535660]  INFO -- amazon_crawler: Session: finished get request to: https://www.amazon.com/Python-Web-Scraping-Cookbook-scraping/dp/1787285219/
I, [2018-08-06 12:22:01 +0400#1686] [Child: 47180448535660]  INFO -- amazon_crawler: Stats visits: requests: 5, responses: 3
I, [2018-08-06 12:22:01 +0400#1686] [Child: 47180448535660]  INFO -- amazon_crawler: Session: started get request to: https://www.amazon.com/Scraping-Python-Community-Experience-Distilled/dp/1782164367/
I, [2018-08-06 12:22:02 +0400#1686] [Child: 47180448490460]  INFO -- amazon_crawler: Session: finished get request to: https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491910291/

...

I, [2018-08-06 12:22:29 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Crawler: in_parallel: stopped processing 53 urls within 3 threads, total time: 30s
I, [2018-08-06 12:22:29 +0400#1686] [Main: 47180432147960]  INFO -- amazon_crawler: Crawler: stopped: {:crawler_name=>"amazon_crawler", :status=>:completed, :environment=>"development", :start_time=>2018-08-06 12:21:48 +0400, :stop_time=>2018-08-06 12:22:29 +0400, :running_time=>"40s", :session_id=>nil, :visits=>{:requests=>54, :responses=>54, :requests_errors=>{}}, :error=>nil, :server=>{:hostname=>"my-pc", :ipv4=>"192.168.0.2", :process_pid=>1686}}
```
</details>

<details/>
  <summary>books.json</summary>

```json
[
  {
    "title": "Web Scraping with Python: Collecting More Data from the Modern Web2nd Edition",
    "url": "https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491985577/",
    "price": "$26.94",
    "publisher": "O'Reilly Media; 2 edition (April 14, 2018)",
    "position": 1
  },
  {
    "title": "Python Web Scraping Cookbook: Over 90 proven recipes to get you scraping with Python, micro services, Docker and AWS",
    "url": "https://www.amazon.com/Python-Web-Scraping-Cookbook-scraping/dp/1787285219/",
    "price": "$39.99",
    "publisher": "Packt Publishing - ebooks Account (February 9, 2018)",
    "position": 2
  },
  {
    "title": "Web Scraping with Python: Collecting Data from the Modern Web1st Edition",
    "url": "https://www.amazon.com/Web-Scraping-Python-Collecting-Modern/dp/1491910291/",
    "price": "$15.75",
    "publisher": "O'Reilly Media; 1 edition (July 24, 2015)",
    "position": 3
  },

  ...

  {
    "title": "Instant Web Scraping with Java by Ryan Mitchell (2013-08-26)",
    "url": "https://www.amazon.com/Instant-Scraping-Java-Mitchell-2013-08-26/dp/B01FEM76X2/",
    "price": "$35.82",
    "publisher": "Packt Publishing (2013-08-26) (1896)",
    "position": 53
  }
]
```
</details><br>

Note that `save_to` and `unique?` helpers are thread-safe (protected by [Mutex](https://ruby-doc.org/core-2.5.1/Mutex.html)) and can be freely used inside threads.

`in_parallel` can take additional options:
* `data:` pass with urls custom data hash: `in_parallel(:method, 3, urls: urls, data: { category: "Scraping" })`
* `delay:` set delay between requests: `in_parallel(:method, 3, urls: urls, delay: 2)`. Delay can be `Integer`, `Float` or `Range` (`2..5`). In case of a range, delay number will be chosen randomly for each request: `rand (2..5) # => 3`
* `driver:` set custom driver than a default one: `in_parallel(:method, 3, urls: urls, driver: :poltergeist_phantomjs)`
* `config:` pass custom options for config (see config section)

### Active Support included

You can use all the power of familiar [Rails core-ext methods](https://guides.rubyonrails.org/active_support_core_extensions.html#loading-all-core-extensions) for scraping inside Kimurai. Especially take a look at [squish](https://apidock.com/rails/String/squish), [truncate_words](https://apidock.com/rails/String/truncate_words), [titleize](https://apidock.com/rails/String/titleize), [remove](https://apidock.com/rails/String/remove), [present?](https://guides.rubyonrails.org/active_support_core_extensions.html#blank-questionmark-and-present-questionmark) and [presence](https://guides.rubyonrails.org/active_support_core_extensions.html#presence).

### Schedule crawlers using Cron

1) Inside crawler file directory generate [Whenever](https://github.com/javan/whenever) config: `$ kimurai generate schedule`.

<details/>
  <summary><code>schedule.rb</code></summary>

```ruby
### Settings ###
require 'tzinfo'

# Export current PATH to the cron
env :PATH, ENV["PATH"]

# Use 24 hour format when using `at:` option
set :chronic_options, hours24: true

# Use local_to_utc helper to setup execution time using your local timezone instead
# of server's timezone (which is probably and should be UTC, to check run `$ timedatectl`).
# Also maybe you'll want to set same timezone in kimurai as well (`Kimurai.configuration.time_zone =`)
# to have crawlers logs in specific time zone format
# Example usage of helper:
# every 1.day, at: local_to_utc("7:00", zone: "Europe/Moscow") do
#   start "google_crawler.com", output: "log/google_crawler.com.log"
# end
def local_to_utc(time_string, zone:)
  TZInfo::Timezone.get(zone).local_to_utc(Time.parse(time))
end

# Note: by default Whenever exports cron commands with :environment == "production".
# Note: Whenever can only append log data to a log file (>>). If you want
# to overwrite (>) log file before each run, pass lambda:
# start "google_crawler.com", output: -> { "> log/google_crawler.com.log 2>&1" }

# project job types
job_type :start,  "cd :path && KIMURAI_ENV=:environment bundle exec kimurai start :task :output"
job_type :runner, "cd :path && KIMURAI_ENV=:environment bundle exec kimurai runner --jobs :task :output"

# single file job type
job_type :single, "cd :path && KIMURAI_ENV=:environment ruby :task :output"
# single with bundle exec
job_type :single_bundle, "cd :path && KIMURAI_ENV=:environment bundle exec ruby :task :output"

### Schedule ###
# Usage (check examples here https://github.com/javan/whenever#example-schedulerb-file):
# every 1.day do
  # Example to schedule single crawler in the project:
  # start "google_crawler.com", output: "log/google_crawler.com.log"

  # Example to schedule all crawlers in the project using runner. Each crawler will write
  # it's own output to the `log/crawler_name.log` file (handled by runner itself).
  # Runner output will be written to log/runner.log file.
  # Argument number it's a count of concurrent jobs:
  # runner 3, output:"log/runner.log"

  # Example to schedule single crawler file (without project)
  # single "single_crawler.rb", output: "single_crawler.log"
# end

### How to set cron schedule ###
# Run: `$ whenever --update-crontab --load-file config/schedule.rb`.
# If you don't have whenever command, install gem: `$ gem install whenever`.

### How to cancel schedule ###
# Run: `$ whenever --clear-crontab --load-file config/schedule.rb`.
```
</details><br>

2) Add at the bottom of file `schedule.rb` following code:

```ruby
every 1.day, at: "7:00" do
  single "example_crawler.rb", output: "example_crawler.log"
end
```

3) Run: `$ whenever --update-crontab --load-file schedule.rb`. Done!

You can check Whenever examples [here](https://github.com/javan/whenever#example-schedulerb-file). To cancel schedule, run: `$ whenever --clear-crontab --load-file schedule.rb`.

### Automated sever setup and deployment
> EXPERIMENTAL

#### Setup
You can automatically setup [required environment](#installation) for Kimurai on the remote server (currently there is only Ubuntu Server 18.04 support) using `$ kimurai setup` command. `setup` will perform installation of: latest Ruby with Rbenv, browsers with webdrivers and in additional databases clients (only clients) for MySQL, Postgres and MongoDB (so you can connect to a remote database from ruby).

> To perform remote server setup, [Ansible](https://github.com/ansible/ansible) is required **on the desktop** machine (to install: Ubuntu: `$ sudo apt install ansible`, Mac OS X: `$ brew install ansible`)

Example:

```bash
$ kimurai setup deploy@123.123.123.123 --ask-sudo --ssh-key-path path/to/private_key
```

CLI options:
* `--ask-sudo` pass this option to ask sudo (user) password for system-wide installation of packages (`apt install`)
* `--ssh-key-path path/to/private_key` authorization on the server using private ssh key. You can omit it if required key already [added to keychain](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#adding-your-ssh-key-to-the-ssh-agent) on your desktop (Ansible uses [SSH agent forwarding](https://developer.github.com/v3/guides/using-ssh-agent-forwarding/))
* `--ask-auth-pass` authorization on the server using user password, alternative option to `--ssh-key-path`.
* `-p port_number` custom port for ssh connection (`-p 2222`)

> You can check setup playbook [here](lib/kimurai/automation/setup.yml)

#### Deploy

After successful `setup` you can deploy a crawler to the server using `$ kimurai deploy` command. On each deploy there are performing several tasks: 1) pull repo from remote origin to `~/repo_name` directory 2) run `bundle install` 3) Update crontab `whenever --update-crontab` (to update crawler schedule from schedule.rb file).

Before `deploy` make sure that inside crawler directory you have: 1) git repository with remote origin (bitbucket, github, etc.) 2) `Gemfile` 3) schedule.rb inside subfolder `config` (`config/schedule.rb`).

Example:

```bash
$ ls -a
Gemfile Gemfile.lock .git/ config/

$ kimurai deploy deploy@123.123.123.123 --ssh-key-path path/to/private_key --repo-key-path path/to/repo_private_key
```

CLI options: same like for [setup](#setup) command (except `--ask-sudo`) +
* `--repo-url` provide custom repo url (`--repo-url git@bitbucket.org:username/repo_name.git`), otherwise current `origin/master` will be taken (output from `$ git remote get-url origin`)
* `--repo-key-path` if git repository is private, authorization is required to pull the code on the remote server. Use this option to provide a private repository SSH key. You can omit it if required key already added to keychain on your desktop (same like with `--ssh-key-path` option)

> You can check deploy playbook [here](lib/kimurai/automation/deploy.yml)


<!-- ### parallel crawling (), delay -->
<!-- yes, proxy and headers are changeable + memory control and auto reloading (see configuration). -->

<!-- at_start at_stop callbacks -->

<!-- ## Custom configuration -->

<!-- @config -->


<!-- helpers, uniq helper with to_id -->

<!-- debugging and development env (pry (ls method), byebug), HEADLESS=false -->

<!-- articles about capybara and nokogiri -->

<!-- <details/>
  <summary>List details</summary>

```ruby
puts "check"
```
</details> -->


<!-- ### Content
* Selectors - xpath or css. For capybara default is xpath. -->
