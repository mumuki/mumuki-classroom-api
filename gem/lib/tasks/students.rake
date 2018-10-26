namespace :students do
  namespace :reports do
    task :registered, [:organization, :course, :from, :to, :format] do |_t, args|
      args.with_defaults(format: 'table')

      from = Date.parse(args[:from])
      to = args[:to].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      stats = Student.report(organzation: args[:organization], course: args[:course]).select do |user|
        Date.parse(user[:created_at]) >= from && Date.parse(user[:created_at]) < to
      end
      puts Classroom::Reports::Formats.format_report(format, stats)
    end

    task :active, [:organization, :course, :from, :to, :format] do |_t, args|
      args.with_defaults(format: 'table')

      from = Date.parse(args[:from])
      to = args[:to].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      stats = Student.report(organization: args[:organization], course: args[:course]).select do |user|
        (user[:detached_at].blank? || Date.parse(user[:detached_at]) >= from) && Date.parse(user[:created_at]) < to
      end
      puts Classroom::Reports::Formats.format_report(format, stats)
    end
  end
end
