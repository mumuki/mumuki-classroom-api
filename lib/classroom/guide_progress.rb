class Classroom::GuideProgress
  extend Classroom::WithMongo

  def self.by_slug(slug)
    guides_progress_collection.by_slug slug
  end

  def self.exercise_by_student(slug, student_id, exercise_id)
    guide_progress = guides_progress_collection.get_exercise slug, student_id
    guide_progress.tap do |gp|
      gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
      gp.delete 'exercises'
    end
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

  def self.process_params(data)
    params = {}
    params['guide'] = data['guide']
    params['submitter'] = data['submitter']
    params['course'] = CourseStudent.find_by('student.social_id' => data['submitter']['social_id'])['course']

    params['exercise'] = {
      id: data['exercise']['id'],
      name: data['exercise']['name'],
      number: data['exercise']['number'],
      submission: {
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

end
