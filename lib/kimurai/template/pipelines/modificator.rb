class Modificator < Kimurai::Pipeline
  def self.open_crawler
  end

  def process_item(item)

    item
  end

  # Each pipeline class inherited from Kimurai::Pipeline has class method `crawler`,
  # which is point to a current crawler class. You can use `crawler.info[:status]`
  # (or `crawler.completed?`, `crawler.failed?`) to determine the stopping status
  # of crawler in .close_crawler method of pipeline. Here is an example:
  # You have a pipeline Saver which is inside .open_crawler openes json file, during
  # #process_item(item) saves each item to this file, and when calling .close_crawler
  # will send this file to an remote ftp. Probably, in case if crawler had failed run
  # you don't want to send incopleted data to an ftp. So to check if run was successful
  # or not use crawler.completed? which is give you `true` if run was successful
  # and false if not.
  def self.close_crawler
  end
end
