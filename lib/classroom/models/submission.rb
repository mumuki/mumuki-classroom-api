require 'net/http'

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
  field :comments, type: Array

  embeds_many :messages

  def add_message!(message)
    self.messages << Message.new(message.as_json)
  end

  def expectation_results
    self[:expectation_results]&.map do |expectation|
      {html: Mumukit::Inspection::I18n.t(expectation), result: expectation['result']}
    end
  end

  def thread
    {content: Mumukit::ContentType::Markdown.to_html(Mumukit::ContentType::Markdown.highlighted_code 'haskell', content), messages: messages} if messages.present?
  end

end

module Mumukit
  module ContentType
    class Markdown

      #TODO: Remove this module when mumukit-content-type gem is fixed
      def self.to_html(markdown)
        if ENV['RACK_ENV'] != 'test'
          uri = URI('http://bibliotheca-api.localmumuki.io:9292/markdown')
          req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
          req.body = {markdown: markdown}.to_json

          response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end

          JSON.parse(response.body)['markdown']
        else
          markdown
        end
      end

      #TODO: Fix this method into mumukit-content-type class
      def self.highlighted_code(language, code)
        "```#{language}\n#{code}\n```"
      end
    end
  end
end
