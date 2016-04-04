class Mongo::Collection
  def upsert(json)

    json.deep_symbolize_keys!

    result = find('guide' => json[:guide], 'student.social_id' => json[:submitter][:social_id], 'course' => json[:course])

    course_student = Classroom::CourseStudent.find_by('student.social_id' => json[:submitter][:social_id])
    course_student.deep_symbolize_keys!

    json[:submitter][:first_name] = course_student[:student][:first_name]
    json[:submitter][:last_name] = course_student[:student][:last_name]

    if result.count.zero?

      insert_one({guide: json[:guide], student: json[:submitter], course: json[:course],
                  exercises: [{id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]]}]})

    else
      result2 = find({ 'guide.slug' => json[:guide][:slug], 'student.social_id' => json[:submitter][:social_id], 'course.slug' => json[:course][:slug], 'exercises.id' => json[:exercise][:id] })

      if result2.count.zero?
        update_one(
            { 'guide' => json[:guide], 'student' => json[:submitter], 'course' => json[:course] },
            { '$push' => {'exercises' => { id: json[:exercise][:id], name: json[:exercise][:name], submissions: [json[:exercise][:submission]] } } },
            { 'upsert' => true })
      else
        update_one(
            { 'guide.slug' => json[:guide][:slug], 'student.social_id' => json[:submitter][:social_id], 'course.slug' => json[:course][:slug], 'exercises.id' => json[:exercise][:id] },
            { '$push' => { 'exercises.$.submissions' => json[:exercise][:submission] }, '$set' => { student: json[:submitter] }})
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

  def students_by_course_slug(course)
    distinct('student', 'course.slug' => course)
  end

  def guide_data(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("guide" => 1, "_id" => 0).limit(1).first
  end

  def by_course_slug(slug)
    distinct('guide', {'course.slug' => slug})
  end

  def get_exercise(slug, student_id, course_slug)
    find('guide.slug' => slug, 'student.social_id' => student_id, 'course.slug' => course_slug).projection(_id: 0).first
  end
end
