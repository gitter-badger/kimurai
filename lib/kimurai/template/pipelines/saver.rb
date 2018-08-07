class Saver < Kimurai::Pipeline
  def process_item(item, options: {})
    # Here you can save item to the database, send it to a remote API or
    # simply save item to a file format using `save_to` helper:

    # to get the name of current crawler: `self.class.crawler.name`
    save_to "db/#{self.class.crawler.name}.json", format: :json

    item
  end
end
