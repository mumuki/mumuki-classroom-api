class Submission

  extend WithQueries

  def self.insert! data, env
    self.save! :submissions, data, env
  end

end
