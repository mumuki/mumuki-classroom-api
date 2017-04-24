class Message

  include Mongoid::Document

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :created_at, type: Time
  field :type, type: String
  field :date, type: String

  def content
    Mumukit::ContentType::Markdown.to_html(self[:content])
  end

  def self.import_from_json!(json)
    Assignment
      .find_by!(organization: json[:organization], 'exercise.eid': json[:exercise][:bibliotheca_id], 'student.uid': json[:sender])
      .add_message!({content: json[:content], sender: json[:sender]}, json[:submission_id])
  end

end
