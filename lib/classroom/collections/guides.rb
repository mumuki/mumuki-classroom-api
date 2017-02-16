class Classroom::Collection::Guides < Classroom::Collection::CourseCollection

  def update!(guide)
    mongo_collection.update_one(query(slug: guide[:slug]), {:'$set' => guide}, {upsert: true})
  end

  def delete_if_has_no_progress
    all.raw.each do |guide|
      delete_one query(slug: guide.slug) unless Classroom::Collection::GuideStudentsProgress.for(organization, course).any?('guide.slug' => guide.slug)
    end
  end

  def migrate_parent(guide)
    parent_data = {type: 'Lesson', name: guide.name, position: guide.lesson['id'], chapter: guide.lesson}

    mongo_collection.update_one({slug: guide.slug}, {:'$set' => guide.as_json.merge(parent: parent_data)}, {upsert: true})
  end

  def transfer(slug, destination)
    Classroom::Collection::Guides
      .for(destination)
      .update! find_by(slug: slug).raw.deep_symbolize_keys
  end

end
