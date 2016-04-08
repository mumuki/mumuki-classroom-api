class Mongo::Collection
  def upsert(data)
    json = data.deep_symbolize_keys

    course_student = Classroom::CourseStudent.find_by('student.social_id' => json[:submitter][:social_id]).deep_symbolize_keys

    json[:submitter][:first_name] = course_student[:student][:first_name]
    json[:submitter][:last_name] = course_student[:student][:last_name]

    result = find('guide' => json[:guide], 'student.social_id' => json[:submitter][:social_id], 'course' => json[:course])

    if result.count.zero?
      insert_one({guide: json[:guide], student: json[:submitter], course: json[:course], exercises: [make_exercise_json(json)]})
    else
      exercise_query = {'guide.slug' => json[:guide][:slug], 'student.social_id' => json[:submitter][:social_id], 'course.slug' => json[:course][:slug], 'exercises.id' => json[:exercise][:id]}

      if find(exercise_query).count.zero?
        insert_new_exercise(json)
      else
        add_submission_to_exercise(exercise_query, json)
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
    uniq('student', { 'course.slug' => course }, 'social_id')
  end

  def guide_data(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("guide" => 1, "_id" => 0).limit(1).first
  end

  def by_course_slug(slug)
    uniq('guide', { 'course.slug' => slug }, 'slug')
  end

  def get_exercise(slug, student_id, course_slug)
    find('guide.slug' => slug, 'student.social_id' => student_id, 'course.slug' => course_slug).projection(_id: 0).first
  end

  def uniq(key, filter, uniq_value)
    distinct(key, filter).uniq { |result| result[uniq_value] }
  end

  def update_follower(course, email, follower, action)
    update_one(
      { "email" => email, "course" => course },
      { action => { "social_ids" => follower }},
      { :upsert => true })
  end

  private

  def insert_new_exercise(json)
    update_one(
      {'guide' => json[:guide], 'student' => json[:submitter], 'course' => json[:course]},
      {'$push' => {'exercises' => make_exercise_json(json)}},
      {'upsert' => true})
  end

  def add_submission_to_exercise(exercise_query, json)
    update_one(exercise_query, {'$push' => {'exercises.$.submissions' => json[:exercise][:submission]}})
  end

  def make_exercise_json(json)
    {id: json[:exercise][:id], name: json[:exercise][:name], number: json[:exercise][:number], submissions: [json[:exercise][:submission]]}
  end
end
