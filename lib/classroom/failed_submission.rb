module Classroom::FailedSubmission

  #FIXME this code should be added to a failed submission document

  def self.reprocess!(uid, destination)
    Classroom::Database.connect!
    reprocess_from_organization uid, destination, destination
    reprocess_from_organization uid, :central, destination
  end

  def self.from(exercise_student_progress)
    progress = exercise_student_progress.raw.deep_symbolize_keys
    progress[:submissions].each do |it|
      Classroom::Collection::FailedSubmissions.insert! new_failed_submission(progress, it).wrap_json
    end
  end

  private

  def self.reprocess_from_organization(uid, source, destination)
    Classroom::Collection::FailedSubmissions.for(source).find_by_uid(uid).each do |failed_submission|
      delete_failed_submission failed_submission, source
      try_reprocess failed_submission, source, destination
    end
  end

  def self.try_reprocess(failed_submission, source, destination)
    begin
      reprocess_failed_submission destination, failed_submission
    rescue => e
      Mumukit::Nuntius::Logger.warn "Resubmission failed #{e}. it was: #{failed_submission.raw}"
      insert_failed_submission failed_submission, source
    end
  end

  def self.insert_failed_submission(failed_submission, source)
    Classroom::Collection::FailedSubmissions.for(source).insert! failed_submission
  end

  def self.reprocess_failed_submission(destination, it)
    json = it.raw
    json['organization'] = destination
    Classroom::Submission.process! json
  end

  def self.delete_failed_submission(it, source)
    Classroom::Collection::FailedSubmissions.for(source).delete! it.id
  end

  def self.new_failed_submission(progress, submission)
    submission.merge({
                       exercise: guide_from(progress[:exercise]),
                       guide: guide_from(progress[:exercise]),
                       submitter: submitter_from(progress[:student])
                     })
  end

  def self.submitter_from(student)
    {
      uid: student[:uid],
      name: student[:name],
      email: student[:email],
      social_id: student[:social_id],
      image_url: student[:image_url]
    }.compact
  end

  def self.guide_from(guide)
    {
      name: guide[:name],
      slug: guide[:slug],
      parent: guide[:parent],
      lesson: guide[:lesson],
      language: guide[:language]
    }.compact
  end

  def self.exercise_from(exercise)
    {
      id: exercise[:id],
      name: exercise[:name],
      number: exercise[:number]
    }.compact
  end

end
