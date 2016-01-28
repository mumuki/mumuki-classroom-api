module WithMongo
  class Mongo::Collection
    def upsert(json)
      result = find({ "guide" => json[:guide], "student" => json[:submitter] })

      if result.count.zero?
        insert_one( { "guide" => json[:guide], "student" => json[:submitter],
         "exercises" => [{ id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]] }] })

      else
        result2 = find({ "guide" => json[:guide], "student" => json[:submitter], "exercises.id" => json[:exercise][:id] })

        unless result2.count.zero?
          update_one(
            { "guide" => json[:guide], "student" => json[:submitter], "exercises.id" => json[:exercise][:id] },
            { "$push" => { "exercises.$.submissions" => json[:exercise][:submission] } })
        else
          update_one(
            { "guide" => json[:guide], "student" => json[:submitter] },
            { "$push" => { "exercises" => { id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]] }}})
        end
      end
    end

    def by_slug(slug)
      find("guide.slug" => slug)
    end

    def by_course(grants)
      find({ "course.slug" => { "$regex" => grants } })
    end

    def by_course_slug(slug)
      find({ "course.slug" => slug })
    end

    def get_exercise(slug, student_id)
      find("guide.slug" => slug, "student.id" => student_id).first
    end
  end

  def method_missing(name, *args, &block)
    with_query = self
    collection_name = name.to_s.split('_collection').first
    if collection_name && args
      args.first['mongo_client'][collection_name]
    else
      super
    end
  end

end
