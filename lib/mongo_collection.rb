class Mongo::Collection
  def upsert(json)
    result = find({guide: json[:guide], student: json[:submitter], course: json[:course]})

    if result.count.zero?
      insert_one({guide: json[:guide], student: json[:submitter], course: json[:course],
                  exercises: [{id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]]}]})

    else
      result2 = find({:guide => json[:guide], :student => json[:submitter], course: json[:course], 'exercises.id' => json[:exercise][:id]})

      if result2.count.zero?
        update_one(
            {guide: json[:guide], student: json[:submitter], course: json[:course]},
            {'$push' => {'exercises' => {id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]]}}})
      else
        update_one(
            {guide: json[:guide], student: json[:submitter], course: json[:course], 'exercises.id' => json[:exercise][:id]},
            {'$push' => {'exercises.$.submissions' => json[:exercise][:submission]}})
      end
    end
  end

  def by_slug(slug)
    find('guide.slug' => slug)
  end

  def by_course(grants)
    find({'course.slug' => {'$regex' => grants}})
  end

  def by_slug_and_course(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("_id" => 0, "guide" => 0, "exercises.submissions" => {"$slice" => -1})
  end

  def guide_data(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("guide" => 1, "_id" => 0).limit(1).first
  end

  def by_course_slug(slug)
    distinct('guide', {'course.slug' => slug})
  end

  def get_exercise(slug, student_id)
    find('guide.slug' => slug, 'student.social_id' => student_id).sort(_id: -1).projection(_id: 0).first
  end
end
