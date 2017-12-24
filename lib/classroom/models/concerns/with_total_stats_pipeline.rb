module WithTotalStatsPipeline
  def pipeline
    [
      {
        '$addFields': {
          'stats.total': {
            '$sum': %w($stats.passed $stats.passed_with_warnings $stats.failed)
          }
        }
      }
    ]
  end
end
