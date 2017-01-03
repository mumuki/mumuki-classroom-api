def do_migrate!
  Classroom::Database.connect_each! do
    Classroom::Collection::CourseStudents.all.each do |course_student|
      course = course_student.course['slug'].split('/').last
      social_id = course_student.student['social_id']
      Classroom::Collection::Students
        .for(course)
        .update_last_assignment_for social_id
    end
  end
end
