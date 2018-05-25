
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kimurai/version"

Gem::Specification.new do |spec|
  spec.name          = "kimurai"
  spec.version       = Kimurai::VERSION
  spec.authors       = ["Victor Afanasev"]
  spec.email         = ["vicfreefly@gmail.com"]

  spec.summary       = "Modern web scraping and web automation framework written in ruby and based on Capybara"
  spec.homepage      = "https://github.com/vfreefly/kimurai"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = "kimurai"
  spec.require_paths = ["lib"]
  # spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "activesupport"
  spec.add_dependency "capybara", ">= 2.15", "< 4.0"
  spec.add_dependency "murmurhash3"
  spec.add_dependency "nokogiri"
  spec.add_dependency "capybara-mechanize"
  spec.add_dependency "poltergeist"
  spec.add_dependency "selenium-webdriver"
  spec.add_dependency "thor"

  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "headless"
  # spec.add_dependency "parallel"
  spec.add_dependency "pmap"


  spec.add_dependency "sequel"
  spec.add_dependency "sqlite3"
  spec.add_dependency "sinatra-contrib"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
