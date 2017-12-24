module Sorting
  module GuideProgress
    module ByMessages
      def self.pipeline
        [
          {'$lookup': lookup_notifications},
          {'$addFields': filter_unread_notifications},
          {'$unwind': unwind_notifications},
          {'$lookup': lookup_assignments},
          {'$addFields': filter_guide_assignments},
          {'$group': group_by_students_uid},
          {'$addFields': generate_guide_progress},
          {'$addFields': add_progress_count},
          {'$replaceRoot': progress_to_document_root},
        ]
      end

      def self.progress_to_document_root
        {'newRoot': '$progresses'}
      end

      def self.add_progress_count
        {
          'progresses.unread': '$count'
        }
      end

      def self.generate_guide_progress
        {
          'progresses': {'$arrayElemAt': ['$progresses', 0]},
        }
      end

      def self.group_by_students_uid
        {
          '_id': '$student.uid',
          'progresses': {'$push': '$$ROOT'},
          'count': {
            '$sum': {
              '$cond': {
                'if': {'$anyElementTrue': ['$assignments']},
                'then': 1,
                'else': 0
              }
            }
          }
        }
      end

      def self.filter_guide_assignments
        {
          'assignments': {
            '$filter': {
              'as': 'assignment',
              'input': '$assignments',
              'cond': {
                '$eq': %w($$assignment.guide.slug $guide.slug),
              }
            }
          }
        }
      end

      def self.lookup_assignments
        {
          'from': 'assignments',
          'localField': 'notifications.assignment_id',
          'foreignField': '_id',
          'as': 'assignments'
        }
      end

      def self.unwind_notifications
        {
          'path': '$notifications',
          'preserveNullAndEmptyArrays': true
        }
      end

      def self.filter_unread_notifications
        {
          'notifications': {
            '$filter': {
              'as': 'notification',
              'input': '$notifications',
              'cond': {
                '$and': [
                  {'$eq': %w($$notification.organization $organization)},
                  {'$eq': %w($$notification.sender $student.uid)},
                  {'$eq': %w($$notification.course $course)},
                  {'$eq': ['$$notification.read', false]}
                ]
              }
            }
          }
        }
      end

      def self.lookup_notifications
        {
          'from': 'notifications',
          'localField': 'organization',
          'foreignField': 'organization',
          'as': 'notifications'
        }
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
