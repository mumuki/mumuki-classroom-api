class Course

  extend WithMongo

  def self.all(grants, env)
    courses = guides_progress_collection(env).by_course grants
    courses.as_json.map { |a| a['course'] }
  end

end
