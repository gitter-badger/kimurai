# Kimurai

> Note: the gem is under active development and don't have full specified readme yet.

## Into
Kimurai it's a modern web scraping and web automation framework written in ruby on top of Capybara libruary.
Works by default with headless chromium/firefox, phantomjs and mechanize (fake http browser).

**Features:**
* Support **out of box crawling using Headless Chrome, Headless Firefox, PhantomJS** or simple http requests (mechanize fake browser libruary). Each of them have it's own pros and cons.
* Write crawler's code and configuration once, and use it with any supported driver later
* Two modes: one-file for simple crawler, and scrapy-like project with pipelines, configuration, etc.
* Auto memory control: reload browser on the fly when reaching memory limit (simply set limit in the crawler config)
* Parrallel crawling using simple method: `in_parallel(:callback_method, threads_count, urls: urls)`
* Reach configuration for crawlers: set default headers, cookies, enable proxy/user-agents rotation
* Convenient development mode with console, colorized logger and debugger (pry, byebug). Add `HEADLESS=false` env variable before command to quickly switch between headless and normal mode for selenium-like drivers (chrome, firefox).
* Full stats for each crawler's run: requests/items count + web dashboard
* Settings and crawlers inheritation (provide example with category urls and i18n)
* Resume crawling if previous run was failed (using database)
* Auto environment setup (for ubuntu 16.04-18.04) and server deploy using commands `setup` and `deploy`
* Easily schedule crawlers to run using whenever (no need to know cron syntax) configuration
* Command-line runner to run all project crawlers one by one or in parallel
* Active Support included, so you can use super handy methods for scrapping, like `#squish`, `#presence/#present`, `#titelize`, `#truncate`, etc.
* Built-in helper to save items to json/json lines/csv/yaml formats.
* CLI
* etc.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
