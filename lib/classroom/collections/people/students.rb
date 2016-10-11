class Classroom::Collection::Students < Classroom::Collection::People

  def exists_exception
    Classroom::StudentExistsError
  end

  def update!(data)
    query = {social_id:  data[:social_id]}
    update_one(query, { :'$set' => { first_name: data[:first_name], last_name: data[:last_name] }})
  end

  def update_all_stats
    find_projection.each do |student|
      social_id = student.deep_symbolize_keys[:social_id]
      update_all_stats_for(social_id)
    end
  end

  def detach!(social_id)
    mongo_collection.update_one(
      { :social_id => social_id },
      { :$set => { detached: true, detached_at: Time.now }}
    )
  end

  def attach!(social_id)
    mongo_collection.update_one(
      { :social_id => social_id },
      { :$unset => { detached: '', detached_at: '' }}
    )
  end

  def transfer(social_id, org, destination)
    Classroom::Collection::Students.for(destination).insert! find_by(social_id: social_id)
    Classroom::Collection::CourseStudents.insert! student_to_transfer(social_id, org, destination)
    Classroom::Collection::GuideStudentsProgress.for(course).transfer(social_id, destination)
    Classroom::Collection::ExerciseStudentProgress.for(course).transfer(social_id, destination)
    delete_one(social_id: social_id)
  end

  def update_all_stats_for(social_id)
    all_stats = Classroom::Collection::ExerciseStudentProgress.for(course).all_stats(social_id)
    update_one({ social_id: social_id }, { :'$set' => { stats: all_stats }})
  end

  def update_last_assignment_for(social_id)
    last_assignment = Classroom::Collection::GuideStudentsProgress.for(course).last_assignment_for(social_id)
    update_one({ social_id: social_id }, { :'$set' => { last_assignment: last_assignment }})
  end

  def delete!(social_id)
    delete_one(social_id: social_id)
    student = { :'student.social_id' => social_id }
    Classroom::Collection::CourseStudents.delete_many(student.merge(:'course.slug' => course_slug))
    Classroom::Collection::GuideStudentsProgress.for(course).delete_many(student)
    Classroom::Collection::ExerciseStudentProgress.for(course).delete_many(student)
    Classroom::Collection::Guides.for(course).delete_if_has_no_progress
  end

  def student_to_transfer(social_id, org, destination)
    course_student = Classroom::Collection::CourseStudents.find_by_social_id!(social_id)
    json_course_student = course_student.raw.deep_symbolize_keys
    json_course_student[:course] = {slug: Mumukit::Service::Slug.new(org, destination).to_s}
    json_course_student.wrap_json
  end

  def report(course, &block)
    self.for(course).all.raw.select(&block).as_json(only: [:first_name, :last_name, :email, :created_at])
  end

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
