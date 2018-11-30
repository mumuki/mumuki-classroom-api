module WithFailedSubmissionReprocess

  def reprocess!(uid, destination)
    reprocess_from_organization uid, destination, destination
    reprocess_from_organization uid, :central, destination
  end

  private

  def reprocess_from_organization(uid, source, destination)
    Mumuki::Classroom::FailedSubmission.for(source).find_by_uid(uid).each do |failed_submission|
      delete_failed_submission failed_submission, source
      try_reprocess failed_submission, source, destination
    end
  end

  def try_reprocess(failed_submission, source, destination)
    begin
      reprocess_failed_submission destination, failed_submission
    rescue => e
      Mumukit::Nuntius::Logger.warn "Resubmission failed #{e}. it was: #{failed_submission.as_json}"
      insert_failed_submission failed_submission, source
    end
  end

  def insert_failed_submission(failed_submission, source)
    Mumuki::Classroom::FailedSubmission.create! failed_submission.as_json.merge(organization: source)
  end

  def reprocess_failed_submission(destination, it)
    json = it.as_json
    json['organization'] = destination
    Mumuki::Classroom::Submission.process! json
  end

  def delete_failed_submission(it, source)
    Mumuki::Classroom::FailedSubmission.for(source).where(_id: it._id).destroy_all
  end

  def new_failed_submission(progress, submission)
    submission.merge({
                       exercise: exercise_from(progress[:exercise]),
                       guide: guide_from(progress[:guide]),
                       submitter: submitter_from(progress[:student])
                     })
  end

  def submitter_from(student)
    {
      uid: student[:uid],
      name: student[:name],
      email: student[:email],
      social_id: student[:social_id],
      image_url: student[:image_url]
    }.compact
  end

  def guide_from(guide)
    {
      name: guide[:name],
      slug: guide[:slug],
      parent: guide[:parent],
      lesson: guide[:lesson],
      language: guide[:language]
    }.compact
  end

  def exercise_from(exercise)
    {
      eid: exercise[:eid],
      name: exercise[:name],
      number: exercise[:number]
    }.compact
  end
end
