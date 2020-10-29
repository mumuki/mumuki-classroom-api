class Mumuki::Classroom::Event::ProgressTransfer
  attr_reader :body

  def initialize(body)
    @body = body
  end

  def execute!
    transfer_type.new(progress_item, source_organization, destination_organization).execute!
  end

  def source_organization
    Organization.locate! body[:from]
  end

  def destination_organization
    Organization.locate! body[:to]
  end

  def progress_item
    Indicator.find(body[:item_id])
  end

  def transfer_type
    self.class.const_get(body[:transfer_type].camelize)
  end
end

require_relative 'progress_transfer/base'
require_relative 'progress_transfer/copy'
require_relative 'progress_transfer/move'
