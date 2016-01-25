module WithParameterConverter

  def convert(parameters)
    parameters.as_json['parameters']
  end


end
