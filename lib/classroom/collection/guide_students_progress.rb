class Classroom::Collection::GuideStudentsProgress < Classroom::Collection::CourseCollection

  def update!(guide_student)
    mongo_collection.update_one(query_by_index(guide_student), { :'$set' => guide_student }, { upsert: true })
  end

  def last_assignment_for(social_id)
    guide_student_progress = first_by({'student.social_id' => social_id }, { 'last_assignment.submission.created_at' => -1 })
    guide_student_progress.try do |it|
      {
        guide: { slug: it.guide['slug'] },
        exercise: it.last_assignment['exercise'],
        submission: {
          id: it.last_assignment['submission']['id'],
          status: it.last_assignment['submission']['status'],
          created_at: it.last_assignment['submission']['created_at'],
        }
      }
    end
  end

  private

  def query_by_index(guide_student)
    { :'guide.slug' => guide_student[:guide][:slug],
      :'student.social_id' => guide_student[:student][:social_id] }
  end

end
