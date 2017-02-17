class Classroom::Event::CourseChanged
  class << self

    def execute!(course)
      course_h = course[:course]
      uid = course_h[:uid]
      Classroom::Database.connect!
      Classroom::Collection::Courses.ensure_new! uid
      Classroom::Collection::Courses.upsert! course_h
    end

  end
end
