module WithoutMongoId

  def as_json(options = {})
    super(options.merge(symbolize: true)).except('_id', :_id).compact.with_indifferent_access
  end

end
