class Classroom::Collection::GuideStudentsProgress < Classroom::Collection::CourseCollection

  def update!(guide_student)
    mongo_collection.update_one(query_by_index(guide_student), { :'$set' => guide_student }, { upsert: true })
  end

  def last_assignment_for(social_id)
    guide_student_progress = first_by({'student.social_id' => social_id }, { 'last_assignment.submission.created_at' => -1 })
    guide_student_progress.try do |it|
      {
        guide: it.guide,
        exercise: it.last_assignment['exercise'],
        submission: {
          id: it.last_assignment['submission']['id'],
          status: it.last_assignment['submission']['status'],
          created_at: it.last_assignment['submission']['created_at'],
        }
      }
    end
  end

  def delete_student!(social_id)
    mongo_collection.delete_many(:'student.social_id' => :social_id)
  end

  def detach_student!(social_id)
    mongo_collection.update_many(
      { :'student.social_id' => social_id },
      { :$set => { detached: true }}
    )
  end

  def attach_student!(social_id)
    mongo_collection.update_many(
      { :'student.social_id' => social_id },
      { :$unset => { detached: '' }}
    )
  end

  def transfer(social_id, destination)
    where(:'student.social_id' => social_id).raw.each do |guide_progress_data|
      guide_progress = guide_progress_data.raw.deep_symbolize_keys
      Classroom::Collection::GuideStudentsProgress.for(destination).insert! guide_progress_data
      Classroom::Collection::Guides.for(course).transfer(guide_progress[:guide][:slug], destination)
    end
    delete_student!(social_id)
    Classroom::Collection::Guides.for(course).delete_if_has_no_progress
  end

  private

  def query_by_index(guide_student)
    { :'guide.slug' => guide_student[:guide][:slug],
      :'student.social_id' => guide_student[:student][:social_id] }
  end

end
