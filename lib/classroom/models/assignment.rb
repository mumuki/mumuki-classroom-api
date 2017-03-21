class Assignment

  include Mongoid::Document
  include Mongoid::Timestamps

  field :guide, type: Hash
  field :student, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  embeds_one :exercise
  embeds_many :submissions

  create_index({'organization': 1, 'course': 1, 'student.uid': 1})
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'exercise.eid': 1, 'student.uid': 1})
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'student.uid': 1, 'exercise.eid': 1})
  create_index({'guide.slug': 1, 'exercise.eid': 1}, {name: 'ExBibIdIndex'})

  def add_message!(message, sid)
    submissions.find_by!(sid: sid).add_message! message
    update_submissions!
    notify_message! message, sid
  end

  def add_submission!(submission)
    self.submissions << Submission.new(submission.as_json)
    update_submissions!
  end

  def notify_message!(message, sid)
    Mumukit::Nuntius.notify! 'messages', json_to_notify(message, sid)
  end

  def json_to_notify(message, sid)
    {
      message: message,
      submission_id: sid,
      exercise_id: exercise.eid,
      tenant: organization
    }.as_json
  end

  def threads
    submissions.map(&:thread).compact
  end

  private

  def update_submissions!
    update_attributes! submissions: submissions
  end

  class << self
    def detach_all_by!(query)
      where(query).set(detached: true)
    end

    def attach_all_by!(query)
      where(query).unset(:detached)
    end

    def destroy_all_by!(query)
      where(query).destroy
    end

    def empty_stats
      {passed: 0, failed: 0, passed_with_warnings: 0}
    end

    def stats_by(query)
      stats = where(query)
                .map { |assignment| assignment.submissions.max_by(&:created_at) }
                .group_by { |submission| submission.status }
                .map { |status, submissions| [status.to_sym, submissions.size] }
                .to_h.compact
      stats = empty_stats.merge(stats)
      stats[:failed] += stats.delete(:errored) || 0
      stats.slice(*empty_stats.keys)
    end
  end

end
