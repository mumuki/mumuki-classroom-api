class Classroom::Course
  extend Classroom::WithMongo

  def self.all(grants)
    courses = guides_progress_collection.by_course grants
    courses.as_json.map { |a| a['course'] }.to_set
  end
end
