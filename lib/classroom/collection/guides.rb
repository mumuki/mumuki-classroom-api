class Classroom::Collection::Guides < Classroom::Collection::CourseCollection

  def update!(guide)
    mongo_collection.update_one({ slug: guide[:slug] }, { :'$set' => guide }, { upsert: true })
  end

end
