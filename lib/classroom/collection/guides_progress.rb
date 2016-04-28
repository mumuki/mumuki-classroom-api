module Classroom::Collection::GuidesProgress

  extend Mumukit::Service::Collection

  def self.by_course_slug(slug)
    uniq('guide', { 'course.slug' => slug }, 'slug')
  end

  def self.guide_data(slug, course)
    mongo_collection.find('course.slug' => course, 'guide.slug' => slug).
      projection('guide' => 1, '_id' => 0).limit(1).first.
      try { |it| wrap it }
  end

  def self.by_slug_and_course(slug, course)
    where({ 'course.slug' => course, 'guide.slug' => slug},
          { 'guide' => 0, 'exercises.submissions' => { '$slice' => -1 }})
  end

  def self.students_by_course_slug(course)
    uniq('student', { 'course.slug' => course }, 'social_id')
  end

  def self.exercise_by_student(course_slug, slug, student_id, exercise_id)
    guide_progress = get_exercise(slug, student_id, course_slug).as_json
    guide_progress.tap do |gp|
      gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
      gp.delete 'exercises'
    end
  end

  def self.by_course(slug)
    by_course_slug slug
  end

  def self.update!(data)
    json = process_params(data).deep_symbolize_keys

    course_student = Classroom::Collection::CourseStudents.find_by!('student.social_id' => json[:submitter][:social_id]).as_json.deep_symbolize_keys

    json[:submitter][:first_name] = course_student[:student][:first_name]
    json[:submitter][:last_name] = course_student[:student][:last_name]

    return if submission_exist? json

    unless guide_exist? json
      create_guide! json
      return
    end

    if exercise_exist? json
      add_submission_to_exercise! json
    else
      create_exercise! json
    end
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
    find_by('guide.slug' => slug, 'student.social_id' => student_id, 'course.slug' => course_slug)
  end

  def self.course_for(social_id)
    Classroom::Collection::CourseStudents.find_by!('student.social_id' => social_id).course
  end

  def self.make_exercise_json(json)
    json[:exercise].tap do |it|
      it[:submissions] = [ it[:submission] ]
    end
  end

  def self.make_exercise_query(json)
    make_guide_query(json).merge('exercises.id' => json[:exercise][:id])
  end

  def self.make_guide_query(json)
    {'guide.slug' => json[:guide][:slug],
     'student.social_id' => json[:submitter][:social_id],
     'course.slug' => json[:course][:slug]}
  end

  def self.guide_exist?(json)
    any? make_guide_query(json)
  end

  def self.exercise_exist?(json)
    any? make_exercise_query(json)
  end

  def self.submission_exist?(json)
    any? make_exercise_query(json).merge('exercises.submissions' => {'$elemMatch' => {'id' => json[:exercise][:submission][:id]}})
  end

  def self.create_guide!(submission_json)
    guide = {guide: submission_json[:guide],
             student: submission_json[:submitter],
             course: submission_json[:course],
             exercises: [make_exercise_json(submission_json)]}
    insert!(guide.wrap_json)
  end

  def self.create_exercise!(json)
    mongo_collection.update_one(make_guide_query(json), {'$push' => {'exercises' => make_exercise_json(json)}})
  end

  def self.add_submission_to_exercise!(json)
    mongo_collection.update_one(
      make_exercise_query(json),
      {'$push' => {'exercises.$.submissions' => json[:exercise][:submission]},
       '$set' => {'exercises.$.name' => json[:exercise][:name], 'exercises.$.number' => json[:exercise][:number]}})
  end

  private

  def self.mongo_collection_name
    :guides_progress
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::JsonWrapper.new(it)
  end

  def self.wrap_array(it)
    Classroom::Collection::GuideProgressArray.new(it)
  end

end