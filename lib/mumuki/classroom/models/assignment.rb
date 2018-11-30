class Mumuki::Classroom::Assignment

  include Mongoid::Document
  include Mongoid::Timestamps

  field :guide, type: Hash
  field :student, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  embeds_one :exercise
  embeds_many :submissions, class_name: 'Mumuki::Classroom::Submission'

  create_index({'organization': 1, 'course': 1, 'student.uid': 1})
  create_index({'organization': 1, 'exercise.eid': 1, 'student.uid': 1})
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'exercise.eid': 1, 'student.uid': 1})
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'student.uid': 1, 'exercise.eid': 1})
  create_index({'guide.slug': 1, 'exercise.eid': 1}, {name: 'ExBibIdIndex'})

  def evaluate_manually!(sid, comment, status)
    submission = submission(sid)
    submission.evaluate_manually! comment, status
    update_submissions!
  end

  def submission(sid)
    submissions.find_by!(sid: sid)
  end

  def add_message!(message, sid)
    submission = submission(sid)
    submission.add_message! message
    update_submissions!
    submission
  end

  def add_submission!(submission)
    self.submissions << Mumuki::Classroom::Submission.new(submission.as_json)
    update_submissions!
  end

  def notify_message!(message, sid)
    Mumukit::Nuntius.notify! 'teacher-messages', json_to_notify(message, sid)
  end

  def notify_manual_evaluation!(sid)
    assignment = {submission_id: sid}.merge(submission(sid).as_json only: [:status, :manual_evaluation])
    Mumukit::Nuntius.notify_event! 'AssignmentManuallyEvaluated', assignment: assignment
  end

  def json_to_notify(message, sid)
    {
      message: message,
      submission_id: sid,
      exercise_id: exercise.eid,
      organization: organization
    }.as_json
  end

  def threads(language)
    language = guide[:language][:name] if language.blank?
    submissions.map { |it| it.thread(language) }.compact
  end

  def with_full_messages(user)
    self[:submissions] = submissions.map { |it| it.with_full_messages user }
    self
  end

  def add_message_to_submission!(message, sid)
    submission = add_message! message, sid
    notify_message! message, sid
    submission
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

    def transfer_all_by!(query, new_organization, new_course)
      where(query).set(organization: new_organization, course: new_course)
    end

    def empty_stats
      {passed: 0, failed: 0, passed_with_warnings: 0}
    end

    def with_full_messages(query, user)
      where(query)
        .map { |assignment| assignment.with_full_messages(user) }
    end

    def items_to_review(query, exercises)
      passed_exercises_ids = where(query)
                              .map { |assignment| [assignment.exercise.eid, assignment.submissions.max_by(&:created_at)] }
                              .map { |eid , submission| eid if submission.status.passed? }
                              .compact
      exercises.reject { |exercise| passed_exercises_ids.include? exercise[:id] }
                .pluck(:tag_list, :language)
                .flatten
                .uniq
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
