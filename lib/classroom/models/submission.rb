require 'net/http'

class Submission

  extend WithSubmissionProcess
  include Mongoid::Document

  field :sid, type: String
  field :content
  field :created_at, type: Time
  field :expectation_results, type: Array
  field :feedback, type: String
  field :result, type: String
  field :status, type: String
  field :submissions_count, type: Integer
  field :test_results, type: Array
  field :comments, type: Array
  field :manual_correction, type: String

  embeds_many :messages

  def correct!(correction, status)
    self.status = status
    self.manual_correction = correction
  end

  def add_message!(message)
    self.messages << Message.new(message.as_json)
  end

  def expectation_results
    self[:expectation_results]&.map do |expectation|
      {html: Mumukit::Inspection::I18n.t(expectation), result: expectation['result']}
    end
  end

  def thread(language)
    {
      status: status,
      content: Mumukit::ContentType::Markdown.to_html(Mumukit::ContentType::Markdown.highlighted_code language, content || ''),
      messages: messages,
      created_at: created_at
    } if messages.present?
  end

  def manual_correction
    Mumukit::ContentType::Markdown.to_html(self[:manual_correction]) if self[:manual_correction]
  end

  def with_full_messages(user)
    self.tap do |submission|
      submission[:messages] = messages.map do |message|
        message.with_full_messages user
      end
    end
  end

end
