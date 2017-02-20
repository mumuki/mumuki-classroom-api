class Document

  include Mongoid::Document
  include Mongoid::Timestamps

  def as_json(options = {})
    super(options).except('_id').compact
  end

  class << self
    def generate_id
      Mumukit::Service::IdGenerator.next
    end
  end

  create_indexes

end
