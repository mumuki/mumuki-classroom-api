class Classroom::Collection::Students < Classroom::Collection::People

  def exists_exception
    Classroom::StudentExistsError
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

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
