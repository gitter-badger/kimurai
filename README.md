# Kimurai

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
* Two modes: write a single file for simple crawler, or generate Scrapy like project with pipelines, configuration, etc.
* Automatically restart browser when reaching memory limit (memory control) or requests limit (set limit in the crawler config)
* Parallel crawling using simple method: `in_parallel(:callback_name, threads_count, urls: urls)`
* Convenient development mode with console, colorized logger and debugger ([Pry](https://github.com/pry/pry), [Byebug](https://github.com/deivid-rodriguez/byebug)). Add `HEADLESS=false` before command to quickly switch between headless (default) and normal (visible) mode for Selenium-like drivers (Chrome, Firefox).
* Full stats for each crawler run: requests/items count + web dashboard
* Auto environment setup (for ubuntu 16.04-18.04) and deploy using commands `kimurai setup` and `kimurai deploy` ([Ansible](https://github.com/ansible/ansible) under the hood)
* Easily schedule crawlers within cron using [Whenever](https://github.com/javan/whenever) (no need to know cron syntax)
* Command-line runner to run all project crawlers one by one or in parallel
* Built-in helpers to make scraping easy, like `save_to` (save items to JSON, JSON lines, CSV or YAML formats) or `absolute_url/normalize_url`
* `at_start` and `at_stop` callbacks which allows to make something useful (like sending notification) before crawler started or after crawler has been stopped

## Getting To Know

### Minimum required crawler structure

```ruby
class SimleCrawler < Kimurai::Base
  @name = "simple_crawler"
  @driver = :selenium_chrome
  @start_urls = ["https://example.com/"]

  def parse(response, url:, data: {})
  end
end
```
Where class variable `@name` it's a name of crawler.

`@driver` driver for crawler. Available drivers: `:selenium_chrome` (Chrome), `:selenium_firefox` (Firefox), `:poltergeist_phantomjs` (PhantomJS), and `:mechanize` (fake http browser, can't render javascript but very fast and lightweight).

`@start_urls` array of start urls to process inside `parse` method

Method `parse` is the starting method, should always present in crawler class.

`def parse` takes few arguments:
* `response` is `Nokogiri::HTML()` object. Contains parsed HTML code from Capybara (`browser.body`) of currently processed url
* `url` current processed url
* `data` hash which can contain something useful. It uses to pass data between requests.


<details/>
  <summary>Example how to use <code>data</code></summary>

Imagine that there is a product page which doesn't contain product category. Category name present only on category page with pagination. Here we can use data to pass category from `parse_category` to `parse_product` methods:

```ruby
def parse_category(response, url:, data: {})
  category_name = response.xpath("//path/to/category/name").text
  response.xpath("//path/to/products/urls").each do |product_url|
    request_to(:parse_product, url: product_url[:href], data: data.merge(category_name: category_name))
  end

  ###
end

def parse_product(response, url:, data: {})
  item = {}
  item[:category_name] = data[:category_name]

  ###
end

```
</details>



<!-- browser, how request_to works -->

<!-- <details/>
  <summary>List details</summary>

```ruby
puts "check"
```
</details> -->


<!-- ### Content
* Selectors - xpath or css. For capybara default is xpath. -->
