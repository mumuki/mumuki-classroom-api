module WithoutMongoId

  def as_json(options = {})
    super(options).except('_id', :_id).deep_compact.with_indifferent_access
  end

end

class Hash
  def deep_compact()
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
  def deep_compact()
    compact
    each do |e|
      if e.respond_to? :deep_compact
        e.deep_compact
      end
      self.delete(e) if e.nil?
    end
  end
end
