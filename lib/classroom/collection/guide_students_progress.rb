class Classroom::Collection::GuideStudentsProgress < Classroom::Collection::CourseCollection

  def update!(guide_student)
    mongo_collection.update_one(query_by_index(guide_student), { :'$set' => guide_student }, { upsert: true })
  end

  private

  def query_by_index(guide_student)
    { :'guide.slug' => guide_student[:guide][:slug],
      :'student.social_id' => guide_student[:student][:social_id] }
  end

end
