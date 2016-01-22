class Student

  extend WithQueries

  def self.by_id id, env
    self.where :students, { id: id }, env
  end

  def self.exists? id, env
    self.by_id(id, env).count > 0
  end

end
