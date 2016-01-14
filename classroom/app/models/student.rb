class Student

  extend WithQueries

  def self.by_id id, request
    self.where :students, { id: id }, request
  end

  def self.exists? id, request
    self.by_id(id, request).count > 0
  end

end
