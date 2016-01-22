module WithQueries

  def save! type, json, env
    env['mongo_client'][type].insert_one json
  end

  def where type, json, env
    env['mongo_client'][type].find json
  end

end
