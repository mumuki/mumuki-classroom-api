class Mongo::Collection
  def uniq(key, filter, uniq_value)
    distinct(key, filter).uniq { |result| result[uniq_value] }
  end
end
