module Sorting
  module GuideProgress
    module ByName
      def self.order_by(ordering)
        order = ordering.value
        {'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByMessages
      def self.lookup_notifications
        {
          'from': 'notifications',
          'localField': 'organization',
          'foreignField': 'organization',
          'as': 'notifications'
        }
      end

      def self.lookup_assignment
        {
          'from': 'assignments',
          'localField': 'notifications.assignments',
          'foreignField': '_id',
          'as': 'assignment'
        }
      end

      def self.match
        {
          'notifications.course': '$course',
          'notifications.read': false,
          'notifications.sender': '$student.uid',
          'assignment.guide.slug': '$guide.slug'
        }
      end

      def self.group
        {
          '_id': '$notifications.sender',
          'guide_progress': '$$ROOT',
          'guide_progress.notifications_count': {'$sum': 1},
        }
      end

      def self.pipeline
        [
          {'$lookup': lookup_notifications},
          {'$lookup': lookup_assignment},
          {'$match': match},
          {'$group': group},
          {'$replaceRoot': {'newRoot': 'guide_progress'}},
        ]
      end

      def self.order_by(ordering)
        order = ordering.value
        {'notifications_count': order,
         'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByProgress
      def self.pipeline
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

      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'stats.total': order,
         'stats.failed': revert,
         'stats.passed_with_warnings': revert,
         'stats.passed': revert,
         'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByLastSubmissionDate
      def self.order_by(ordering)
        order = ordering.value
        {'last_assignment.submission.created_at': order,
         'last_name': order,
         'first_name': order}
      end
    end
  end
end
