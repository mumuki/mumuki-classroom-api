class Classroom::Reports::Formats
  module Json
    def self.format_report(stats)
      stats.to_json
    end
  end

  module Csv
    def self.format_report(stats)
      stats.to_csv
    end
  end

  module Table
    def self.format_report(stats)
      return '<no data>' if stats.empty?

      header = stats.first.keys.join(' | ')
      body = stats.map { |it| it.values.join(' | ') }.join("\n")
<<EOF
      #{header}
      #{header.size.times.map { '-' }.join}
      #{body}
EOF
    end
  end

  def self.format_for(key)
    "Classroom::Reports::Formats::#{key.capitalize}".constantize
  end

  def self.format_report(key, stats)
    format_for(key).format_report(stats)
  end
end
