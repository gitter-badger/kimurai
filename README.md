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
* Rich configuration: set default headers, cookies, delay between requests, enable proxy/user-agents rotation. Auto retry if a request was failed
* Settings and crawlers inheritation
* **Two modes:** write a single file for simple crawler, or generate Scrapy like **project with pipelines, configuration, etc.**
* Automatically restart browser when reaching memory limit (memory control) or requests limit (set limit in the crawler config)
* Parallel crawling using simple method: `in_parallel(:callback_name, threads_count, urls: urls)`
* Convenient development mode with console, colorized logger and debugger ([Pry](https://github.com/pry/pry), [Byebug](https://github.com/deivid-rodriguez/byebug)). Add `HEADLESS=false` before command to quickly switch between headless (default) and normal (visible) mode for Selenium-like drivers (Chrome, Firefox).
* Full stats for each crawler run: requests/items count + web dashboard
* Auto environment setup (for ubuntu 16.04-18.04) and deploy using commands `kimurai setup` and `kimurai deploy` ([Ansible](https://github.com/ansible/ansible) under the hood)
* Easily schedule crawlers within cron using [Whenever](https://github.com/javan/whenever) (no need to know cron syntax)
* Command-line runner to run all project crawlers one by one or in parallel
* Built-in helpers to make scraping easy, like `save_to` (save items to JSON, JSON lines, CSV or YAML formats) or `absolute_url/normalize_url`
* `at_start` and `at_stop` callbacks which allows to make something useful (like sending notification) before crawler started or after crawler has been stopped

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
* class variable `@name` it's a name of crawler. You can omit name if use single file crawler.
* `@driver` driver for crawler. Available drivers: `:selenium_chrome` (Chrome), `:selenium_firefox` (Firefox), `:poltergeist_phantomjs` (PhantomJS), and `:mechanize` (fake http browser, can't render javascript but very fast and lightweight).
* `@start_urls` array of start urls to process one by one inside `parse` method
* Method `parse` is the starting method, should always present in crawler class.

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
      request_to(:parse_product, url: product_url[:href], data: data.merge(category_name: category_name))
    end

    # ...
  end

  def parse_product(response, url:, data: {})
    item = {}
    item[:category_name] = data[:category_name]

    # ...
  end
end

```
</details>

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

Check out **Capybara cheat sheets** where you can see all available methods:
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
    parse_product(browser.response, url: url_to_process)
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

<!-- ### prevent duplicates, `unique?` helper

### parallel crawling (), delay
yes, proxy and headers are changeable + memory control and auto reloading (see configuration).

## Custom configuration

@config -->





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
