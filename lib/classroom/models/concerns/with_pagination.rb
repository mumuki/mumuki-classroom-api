module WithPagination
  extend ActiveSupport::Concern

  included do
    scope :search, -> (string) { where '$text': {'$search': string, '$language': 'none'} if string.strip.present? }
    scope :with_detached, -> (detached) { where 'detached': {'$exists': false} unless detached }
  end
end
