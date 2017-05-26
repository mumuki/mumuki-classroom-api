class Message

  include Mongoid::Document
  include Mongoid::Timestamps

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :type, type: String
  field :date, type: String

  def content
    Mumukit::ContentType::Markdown.to_html(self[:content])
  end

  def sended_by?(user)
    sender == user.uid
  end

  def with_full_messages(user)
    self.tap do |message|
      message[:is_me] = message.sended_by? user
    end
  end

  def self.import_from_json!(json)
    assignment = Assignment.find_by!(organization: json[:organization], 'exercise.eid': json[:exercise][:bibliotheca_id], 'student.uid': json[:sender])
    assignment.add_message!({content: json[:content], sender: json[:sender]}, json[:submission_id])
    assignment
  end

end
