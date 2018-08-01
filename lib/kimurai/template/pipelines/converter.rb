class Converter < Kimurai::Pipeline
  def self.at_start
  end

  def process_item(item, options: {})

    item
  end

  # Each pipeline class which is inherited from Kimurai::Pipeline has a class method `crawler`,
  # which is point to a current crawler class. You can use `crawler.info[:status]`
  # (or `crawler.completed?`/`crawler.failed?`) to determine the stopping status
  # of crawler in .at_stop method of pipeline.

  # Example: you have a pipeline Saver which is inside .at_start self method opens json file, during
  # #process_item(item) saves each item to this file, and when calling .at_stop
  # will close and send file to an remote ftp. Probably in case if crawler had failed,
  # you don't want to send incopleted data to a remote location. To check if run was successful
  # or not use crawler.completed? which will give you `true` if run was successful
  # and `false` if not.
  def self.at_stop
  end
end
