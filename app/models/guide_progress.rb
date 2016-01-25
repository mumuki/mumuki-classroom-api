class GuideProgress

  extend WithMongo

  def self.by_id(id, env)
    guides_progress_collection(env).where(id: id)
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
      params[model] = { id: data[model]['id'], name: data[model]['name']}
    end
    params['exercise'] = {
      id: data['exercise']['id'],
      name: data['exercise']['name'],
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
