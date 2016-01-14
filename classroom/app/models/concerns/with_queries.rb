module WithQueries

  def save! type, json, request
    request.env['mongo_client'][type].insert_one json
  end

  def where type, json, request
    request.env['mongo_client'][type].find json
  end

end
