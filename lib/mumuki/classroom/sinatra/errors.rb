error Classroom::CourseExistsError do
  halt 400
end

error Classroom::CourseNotExistsError do
  halt 400
end

error Classroom::StudentExistsError do
  halt 400
end

error Classroom::TeacherExistsError do
  halt 400
end

error Mongoid::Errors::DocumentNotFound do
  halt 404
end

error Mongo::Error::OperationFailure do |e|
  halt 422 if e.message =~ /^E11000/
end
