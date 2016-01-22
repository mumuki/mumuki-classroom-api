class ProgressGuide

  extend WithQueries

  def self.by_id id,
   env
    self.where :progress_guides, { id: id }, env
  end

  def self.all env
    self.find :progress_guides
  end

  def self.update! data, env
    params = process_params data
    self.upsert :progress_guides, params, env
  end

  def self.exists? id, env
    self.by_id(id, env).count > 0
  end

  def self.process_params data
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
