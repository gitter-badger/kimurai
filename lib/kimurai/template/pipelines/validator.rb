class Validator < Kimurai::Pipeline
  def self.at_start
    # puts "From validator, before start crawler"
  end

  def process_item(item, options: {})

    item
  end

  def self.at_stop
    # puts "From validator, after stop crawler"
  end
end
