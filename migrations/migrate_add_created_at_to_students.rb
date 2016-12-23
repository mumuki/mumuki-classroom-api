def do_migrate!
  Classroom::Database.within_each do
    Classroom::Collection::CourseStudents.add_created_at_field
  end
end

module Classroom::Collection::CourseStudents
  def self.add_created_at_field
    mongo_collection.find.each do |json|
      data = json.deep_symbolize_keys
      time = data[:_id].generation_time
      course = data[:course][:slug].split('/').last
      social_id = data[:student][:social_id]
      mongo_collection.update_one(
        { :_id => data[:_id] },
        { :$set => { :'student.created_at' => time } }
      )
      Classroom::Collection::Students
        .for(course)
        .add_created_at_field(social_id, time)
    end
  end
end

class Classroom::Collection::Students < Classroom::Collection::People
  def add_created_at_field(social_id, time)
    mongo_collection.update_one(
      { :social_id => social_id },
      { :$set => { :created_at => time } }
    )
  end
end
