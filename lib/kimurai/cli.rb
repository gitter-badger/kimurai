require "thor"

module Kimurai
  class CLI < Thor
    desc "start", "starts the crawler by crawler name"
    def start(crawler_name)

      # Upd все что ниже нужно засовывать в конфиг проекта генеренного. И отсюда его рекварить
      # a уже в файле нужная структура реквайринга. Глянь рельсы.
      Bundler.require(:default, Kimurai.env)

      Dir.glob(File.join('./pipelines', '*.rb'), &method(:require))
      require "./crawlers/application_crawler"
      Dir.glob(File.join('./crawlers', '*.rb'), &method(:require))

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }
      crawler_class.new.parse

      # UPD при new должен смотреть, есть ли старт юрл, если есть
      # автоматом переходить. Нет - тогда просто вызывать парс метод.
      # Поддерживается только старт юрл, не юрлс. Если надо юрлс, тогда
      # Пусть вся логика в парс объявляется.

      # require "pry" ; binding.pry
      # crawler = Base.
    end
  end
end
