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
        Mumuki::Classroom.register_index! self
      end

      def drop_index(index_name)
        collection.indexes.drop_one(index_name) if has_index_named?(index_name)
      end

      def has_index_named?(index_name)
        collection.indexes.any? { |spec| spec['name'] == index_name }
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

  def merge_unless(criterion, hash)
    return merge hash unless criterion
    self
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


class String
  def boolean_value
    downcase.strip == 'true'
  end
end

class TrueClass
  def boolean_value
    self
  end
end

class FalseClass
  def boolean_value
    self
  end
end

class NilClass
  def boolean_value
    false
  end
end
