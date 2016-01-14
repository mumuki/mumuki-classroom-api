class Submission

  extend WithQueries

  def self.insert! data, request
    self.save! :submissions, data, request
  end

end
