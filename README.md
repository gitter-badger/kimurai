# Kimurai

> Note: the gem is under active development and don't have full specified readme yet.

## Into
Kimurai it's a modern web scraping and web automation framework written in ruby on top of Capybara libruary.
Works by default with headless chromium/firefox, phantomjs and mechanize (fake http browser).

**Features:**
* Support out of box crawling using Headless Chrome, Headless Firefox, PhantomJS or simple http requests (mechanize fake browser libruary). Each of them have it's own pros and cons
* Write crawler's code and configuration once, and use it with any supported driver later
* Auto memory control, browsers reloading on the fly when reaching memory limit (simply set limit in the crawler's config)
* Parrallel crawling using simple method: `in_parallel(:callback_method, threads_count, requests: urls)`
* Reach configuration for crawlers: set default headers, cookies, enable proxy/user-agents rotation
* Convenient development mode with console, colorized logger and debugger (pry, byebug)
* Full stats for each crawler's run: requests/items count + web dashboard
* Settings and crawlers inheritation (provide example with category urls and i18n)
* Resume crawling if previous run was failed (using database)
* Auto server setup (ubuntu 16.04-18.04) and deploy using commands `setup` and `deploy`
* Runner to run all project crawlers in parallel
* CLI
* etc.


## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
