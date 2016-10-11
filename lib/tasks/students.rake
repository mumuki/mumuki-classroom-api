namespace :students do
  namespace :reports do
    task :registered, [:organization, :course, :from, :to, :format] do
      args.with_defaults(args: 'table')

      from = Date.parse(args[:from])
      to = args[:to].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      Classroom::Database.with args[:organization] do
        stats = Classroom::Collection::Students.report(args[:course]) do |user|
          user.created_at >= from && user.created_at < to
        end
        puts Classroom::Reports::Formats.format_report(format, stats)
      end
    end

    task :active, [:organization, :course, :from, :to, :format] do
      args.with_defaults(args: 'table')

      from = Date.parse(args[:from])
      to = args[:from].try { |it| Date.parse(it) } || 1.day.since
      format = args[:format]

      Classroom::Database.with args[:organization] do
        stats = Classroom::Collection::Students.report(args[:course]) do |user|
          user.created_at >= from && user.detached_at < to
        end
        puts Classroom::Reports::Formats.format_report(format, stats)
      end
    end
  end
end
