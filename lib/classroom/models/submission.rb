class Submission

  extend WithSubmissionProcess
  include Mongoid::Document

  field :sid, type: String
  field :content, type: String
  field :created_at, type: Time
  field :expectation_results, type: Array
  field :feedback, type: String
  field :result, type: String
  field :status, type: String
  field :submissions_count, type: Integer
  field :test_results, type: Array

  embeds_many :messages

  def add_message!(message)
    self.messages << Message.new(message.as_json)
  end

  def expectation_results
    self[:expectation_results]&.map do |expectation|
      {html: Mumukit::Inspection::I18n.t(expectation), result: expectation['result']}
    end
  end

end
