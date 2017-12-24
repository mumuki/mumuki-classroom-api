module Sorting
  module GuideProgress
    module ByMessages
      def self.lookup_notifications
        {
          'from': 'notifications',
          'localField': 'organization',
          'foreignField': 'organization',
          'as': 'notifications'
        }
      end

      def self.project_notifications
        {
          'notifications': {
            '$filter': {
              'as': 'notification',
              'input': '$notifications',
              'cond': {
                '$and': [
                  {'$eq': ['$$notification.organization', '$organization']},
                  {'$eq': ['$$notification.sender', '$student.uid']},
                  {'$eq': ['$$notification.course', '$course']},
                  {'$eq': ['$$notification.read', false]}
                ]
              }
            }
          }
        }
      end

      def self.project_notifications_count
        {
          'unread': {
            '$size': '$notifications'
          }
        }
      end

      def self.final_projection
        {
          'guide._id': 0,
          'student._id': 0,
          'notifications': 0,
          'last_assignment._id': 0,
          'last_assignment.guide._id': 0,
          'last_assignment.exercise._id': 0,
          'last_assignment.submission._id': 0,
        }
      end

      def self.pipeline
        [
          {'$lookup': lookup_notifications},
          {'$addFields': project_notifications},
          {'$addFields': project_notifications_count},
          {'$project': final_projection},
        ]
      end

      def self.order_by(ordering)
        order = ordering.value
        {'unread': order,
         'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByName
      def self.order_by(ordering)
        order = ordering.value
        {'student.last_name': order,
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
        revert = ordering.negated.value
        {'last_assignment.submission.created_at': revert,
         'last_name': order,
         'first_name': order}
      end
    end
  end
end
