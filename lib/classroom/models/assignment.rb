class Assignment

  include Mongoid::Document
  include Mongoid::Timestamps

  field :guide, type: Hash
  field :student, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  embeds_one :exercise
  embeds_many :submissions

  store_in collection: 'exercise_student_progress'
  create_index({'organization': 1, 'course': 1, 'exercise.eid': 1, 'student.uid': 1})

  def comment!(comment, sid)
    submissions.find_by!(sid: sid).comment! comment
    update_attributes! submissions: submissions
    notify_comment! comment, sid
  end

  def notify_comment!(comment, sid)
    Mumukit::Nuntius::Publisher.publish_comments json_to_notify(comment, sid)
  end

  def json_to_notify(comment, sid)
    {
      comment: comment,
      submission_id: sid,
      exercise_id: exercise.eid,
      tenant: organization
    }.as_json
  end

  def self.detach_all_by!(query)
    where(query).set(detached: true)
  end

  def self.attach_all_by!(query)
    where(query).unset(:detached)
  end

  def self.destroy_all_by!(query)
    where(query).destroy
  end

  def self.stats_by(query)
    where(query)
      .map { |assignment| assignment.submissions.max_by(&:created_at) }
      .group_by { |submission| submission.status }
      .reduce(empty_stats) { |json, (key, value)| json.tap { json[key.to_sym] = value.size || 0 } }
      .slice(*empty_stats.keys)
  end

  def self.empty_stats
    {passed: 0, failed: 0, passed_with_warnings: 0}
  end


end
