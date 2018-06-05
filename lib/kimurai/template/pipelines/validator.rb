class Validator < Kimurai::Pipeline
  def self.open_crawler
    # puts "From validator, open crawler"
  end

  def process_item(item, options: {})

    item
  end

  def self.close_crawler
    # puts "From validator, closed crawler"
  end
end
