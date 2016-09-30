class Class
  def instance_variable_swap(var)
    old = instance_variable_get(var)
    yield
  ensure
    instance_variable_set(var, old)
  end
end
