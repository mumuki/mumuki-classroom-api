class Classroom::Collection::Guides < Classroom::Collection::CourseCollection

  def update!(guide)
    mongo_collection.update_one({ slug: guide[:slug] }, { :'$set' => guide }, { upsert: true })
  end

  def delete_if_has_no_progress
    all.raw.each do | guide |
      delete_one(slug: guide.slug) unless Classroom::Collection::GuideStudentsProgress.for(course).any?('guide.slug' => guide.slug)
    end
  end

end
