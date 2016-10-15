namespace :students do
  namespace :reports do
    task :registered, [:organization, :course, :from, :to, :format] do |_t, args|
      args.with_defaults(format: 'table')

      from = Date.parse(args[:from])
      to = args[:to].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      Classroom::Database.with args[:organization] do
        stats = Classroom::Collection::Students.for(args[:course]).report do |user|
          user.created_at >= from && user.created_at < to
        end
        puts Classroom::Reports::Formats.format_report(format, stats)
      end
    end

    task :active, [:organization, :course, :from, :to, :format] do |_t, args|
      args.with_defaults(format: 'table')

      from = Date.parse(args[:from])
      to = args[:from].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      Classroom::Database.with args[:organization] do
        stats = Classroom::Collection::Students.for(args[:course]).report do |user|
          user.created_at >= from && user.detached_at < to
        end
        puts Classroom::Reports::Formats.format_report(format, stats)
      end
    end
  end

  task :update_last_assignment do
    Classroom::Database.within_each do
      Classroom::Collection::CourseStudents.all.each do |course_student|
        course = course_student.course['slug'].split('/').last
        social_id = course_student.student['social_id']
        Classroom::Collection::Students
          .for(course)
          .update_last_assignment_for social_id
      end
    end
  end

end
