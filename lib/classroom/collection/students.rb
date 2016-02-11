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

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end