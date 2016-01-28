class GuideProgress

  extend WithMongo

  def self.by_slug(slug, env)
    guides_progress_collection(env).by_slug slug
  end

  def self.exercise_by_student(slug, student_id, exercise_id, env)
    guide_progress = guides_progress_collection(env).get_exercise slug, student_id
    guide_progress.tap do |gp|
      gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
      gp.delete 'exercises'
    end
  end

  def self.by_course(grants, env)
    guides_progress_collection(env).by_course grants
  end

  def self.all(env)
    guides_progress_collection(env).find
  end

  def self.update!(data, env)
    params = process_params data
    collection = guides_progress_collection(env)
    collection.upsert params
  end

  def self.exists?(id, env)
    self.by_id(id, env).count > 0
  end

  def self.process_params(data)
    params = {}
    %w(guide submitter).each do |model|
      params[model] = { name: data[model]['name']}
    end
    params['guide'] = data['guide']
    params['submitter'] = data['submitter']

    params['exercise'] = {
      id: data['exercise']['id'],
      name: data['exercise']['name'],
      number: data['exercise']['number'],
      submission: {
        status: data['status'],
        result: data['result'],
        feedback: data['feedback'],
        submissions_count: data['submissions_count'],
        created_at: data['created_at'],
        content: data['content']
      }
    }
    params.symbolize_keys
  end

end
