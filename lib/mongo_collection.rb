class Mongo::Collection
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
end
