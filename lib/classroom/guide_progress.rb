class Classroom::GuideProgress
  extend Classroom::WithMongo

  def self.by_slug(slug)
    guides_progress_collection.by_slug slug
  end

  def self.by_slug_and_course(slug, course)
    guides_progress_collection.by_slug_and_course slug, course
  end

  def self.guide_data(slug, course)
    guides_progress_collection.guide_data slug, course
  end

  def self.exercise_by_student(course_slug, slug, student_id, exercise_id)
    guide_progress = guides_progress_collection.get_exercise slug, student_id, course_slug
    guide_progress.tap do |gp|
      gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
      gp.delete 'exercises'
    end
  end

  def self.students_by_course_slug(course)
    guides_progress_collection.students_by_course_slug(course)
  end

  def self.by_course(slug)
    guides_progress_collection.by_course_slug slug
  end

  def self.all
    guides_progress_collection.find
  end

  def self.update!(data)
    params = process_params data
    guides_progress_collection.upsert params
  end

  def self.exists?(id)
    self.by_id(id).count > 0
  end

  def self.insert!(course_json)
    guides_progress_collection.insert_one(course_json)
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

  def self.course_for(social_id)
    Classroom::CourseStudent.find_by('student.social_id' => social_id)['course']
  end
end
