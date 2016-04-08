class Classroom::GuideProgress
  extend Classroom::WithMongo

  def self.collection_name
    'guides_progress'
  end

  def self.by_slug(slug)
    find('guide.slug' => slug)
  end

  def self.by_course_slug(slug)
    uniq('guide', { 'course.slug' => slug }, 'slug')
  end

  def self.guide_data(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("guide" => 1, "_id" => 0).limit(1).first
  end

  def self.by_slug_and_course(slug, course)
    find('course.slug' => course, 'guide.slug' => slug)
      .projection("_id" => 0, "guide" => 0, "exercises.submissions" => {"$slice" => -1})
  end

  def self.students_by_course_slug(course)
    uniq('student', { 'course.slug' => course }, 'social_id')
  end

  def self.exercise_by_student(course_slug, slug, student_id, exercise_id)
    guide_progress = get_exercise slug, student_id, course_slug
    guide_progress.tap do |gp|
      gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
      gp.delete 'exercises'
    end
  end

  def self.by_course(slug)
    by_course_slug slug
  end

  def self.all
    find
  end

  def self.update!(data)
    json = process_params(data).deep_symbolize_keys

    course_student = Classroom::CourseStudent.find_by('student.social_id' => json[:submitter][:social_id]).deep_symbolize_keys

    json[:submitter][:first_name] = course_student[:student][:first_name]
    json[:submitter][:last_name] = course_student[:student][:last_name]

    if find(make_guide_query json).count.zero?
      insert_one({guide: json[:guide], student: json[:submitter], course: json[:course], exercises: [make_exercise_json(json)]})
    else
      exercise_query = make_guide_query(json).merge('exercises.id' => json[:exercise][:id])

      if find(exercise_query).count.zero?
        insert_new_exercise(json)
      else
        add_submission_to_exercise(exercise_query, json)
      end
    end
  end

  def self.exists?(id)
    self.by_id(id).count > 0
  end

  def self.process_params(data)
    params = {}
    params['guide'] = data['guide']
    params['submitter'] = data['submitter']
    params['course'] = course_for(data['submitter']['social_id'])

    params['exercise'] = {
      id: data['exercise']['id'],
      name: data['exercise']['name'],
      number: data['exercise']['number'],
      submission: {
        id: data['id'],
        status: data['status'],
        result: data['result'],
        expectation_results: data['expectation_results'],
        test_results: data['test_results'],
        feedback: data['feedback'],
        submissions_count: data['submissions_count'],
        created_at: data['created_at'],
        content: data['content']
      }
    }
    params.symbolize_keys
  end

  private

  def self.get_exercise(slug, student_id, course_slug)
    find('guide.slug' => slug, 'student.social_id' => student_id, 'course.slug' => course_slug).projection(_id: 0).first
  end

  def self.course_for(social_id)
    Classroom::CourseStudent.find_by('student.social_id' => social_id)['course']
  end

  def self.insert_new_exercise(json)
    update_one(make_guide_query(json), {'$push' => {'exercises' => make_exercise_json(json)}})
  end

  def self.add_submission_to_exercise(exercise_query, json)
    update_one(exercise_query, {
      '$push' => {'exercises.$.submissions' => json[:exercise][:submission]},
      '$set' => {'exercises.$.name' => json[:exercise][:name], 'exercises.$.number' => json[:exercise][:number]}
    })
  end

  def self.make_exercise_json(json)
    {id: json[:exercise][:id], name: json[:exercise][:name], number: json[:exercise][:number], submissions: [json[:exercise][:submission]]}
  end

  def self.make_guide_query(json)
    {'guide.slug' => json[:guide][:slug], 'student.social_id' => json[:submitter][:social_id], 'course.slug' => json[:course][:slug]}
  end
end
