class Mumuki::Classroom::App < Sinatra::Application
  error Mumuki::Domain::NotFoundError do
    halt 404
  end

  error Mumuki::Classroom::StudentExistsError do
    halt 400
  end

  error Mumuki::Classroom::TeacherExistsError do
    halt 400
  end

  error Mongoid::Errors::DocumentNotFound do
    halt 404
  end

  error Mongo::Error::OperationFailure do |e|
    halt 422 if e.message =~ /^E11000/
  end
end
