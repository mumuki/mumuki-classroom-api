class Mongo::Collection
  def upsert(json)
    result = find({guide: json[:guide], student: json[:submitter]})

    if result.count.zero?
      insert_one({guide: json[:guide], student: json[:submitter],
                  exercises: [{id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]]}]})

    else
      result2 = find({:guide => json[:guide], :student => json[:submitter], 'exercises.id' => json[:exercise][:id]})

      if result2.count.zero?
        update_one(
            {guide: json[:guide], student: json[:submitter]},
            {'$push' => {'exercises' => {id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]]}}})
      else
        update_one(
            {guide: json[:guide], student: json[:submitter], 'exercises.id' => json[:exercise][:id]},
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

  def by_course_slug(slug)
    find({'course.slug' => slug})
  end

  def get_exercise(slug, student_id)
    find('guide.slug' => slug, 'student.id' => student_id).first
  end
end