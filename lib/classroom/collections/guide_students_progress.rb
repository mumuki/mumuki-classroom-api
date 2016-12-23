class Classroom::Collection::GuideStudentsProgress < Classroom::Collection::CourseCollection

  def update!(guide_student)
    mongo_collection.update_one(query_by_index(guide_student), { :'$set' => guide_student }, { upsert: true })
  end

  def last_assignment_for(uid)
    guide_student_progress = first_by({'student.uid': uid }, { 'last_assignment.submission.created_at': -1 })
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

  def detach_student!(uid)
    mongo_collection.update_many(
      { :'student.uid' => uid },
      { :$set => { detached: true }}
    )
  end

  def attach_student!(uid)
    mongo_collection.update_many(
      { :'student.uid' => uid },
      { :$unset => { detached: '' }}
    )
  end

  private

  def query_by_index(guide_student)
    { :'guide.slug' => guide_student[:guide][:slug],
      :'student.uid' => guide_student[:student][:uid] }
  end

end
