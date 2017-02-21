module WithoutMongoId

  def as_json(options = {})
    super(options).except('_id').compact
  end

end
