module WithQueries

  def save! type, json, request
    binding.pry
    request.env['mongo_client'][type].insert_one json
  end
end
