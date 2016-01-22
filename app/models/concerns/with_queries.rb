module WithQueries

  def save!(type, json, env)
    env['mongo_client'][type].insert_one json
  end

  def where(type, json, env)
    env['mongo_client'][type].find json
  end

  def find(type, env)
    env['mongo_client'][type].find
  end

  def upsert(type, json, env)
    result = env['mongo_client'][type].find({ "guide" => json[:guide], "student" => json[:submitter] })

    if result.count.zero?
      env['mongo_client'][type].insert_one( { "guide" => json[:guide], "student" => json[:submitter],
       "exercises" => [{ id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]] }] })

    else
      result2 = env['mongo_client'][type].find({ "guide" => json[:guide], "student" => json[:submitter], "exercises.id" => json[:exercise][:id] })

      unless result2.count.zero?
        env['mongo_client'][type].update_one(
          { "guide" => json[:guide], "student" => json[:submitter], "exercises.id" => json[:exercise][:id] },
          { "$push" => { "exercises.$.submissions" => json[:exercise][:submission] } })
      else
        env['mongo_client'][type].update_one(
          { "guide" => json[:guide], "student" => json[:submitter] },
          { "$push" => { "exercises" => { id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]] }}})

      end
    end
  end

end
