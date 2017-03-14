module Mongoid
  module Document

    def as_json(options = {})
      super(options).as_json(except: ['_id', :_id]).deep_compact.with_indifferent_access
    end

    def upsert_attributes(attrs)
      assign_attributes(attrs)
      upsert
    end

    module ClassMethods
      def create_index(*args)
        index *args
        create_indexes
      end
    end

  end
end


class Hash
  def deep_compact
    compact
    each_pair do |k, v|
      if self[k].respond_to? :deep_compact
        self[k].deep_compact
      end
      self.delete(k) if self[k].nil?
    end
  end
end


class Array
  def deep_compact
    compact
    each do |e|
      if e.respond_to? :deep_compact
        e.deep_compact
      end
      self.delete(e) if e.nil?
    end
  end
end

module Mumukit::Login::LoginControllerHelpers
  private
  def save_current_user_session!(user)
    mumukit_controller.shared_session.tap do |it|
      it.uid = user.uid
      it.profile = {user_name: user.name,
                    user_uid: user.uid,
                    user_image_url: user.image_url}
    end
  end
end

