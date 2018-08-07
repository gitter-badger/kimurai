class Saver < Kimurai::Pipeline
  def process_item(item, options: {})
    # Here you can save item to the database, send it to a remote API or
    # simply save item to a file format using `save_to` helper

    item
  end
end
