module Sorting
  module GuideProgress
    class ByMessages < SortBy
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
        {'unread': ordering,
         'student.last_name': ordering,
         'student.first_name': ordering}
      end
    end

    class ByName < SortBy
      def self.order_by(ordering)
        {'student.last_name': ordering,
         'student.first_name': ordering}
      end
    end

    class ByProgress < SortBy
      extend WithTotalStatsPipeline

      def self.order_by(ordering)
        {'stats.total': ordering,
         'stats.failed': !ordering,
         'stats.passed_with_warnings': !ordering,
         'stats.passed': !ordering,
         'student.last_name': ordering,
         'student.first_name': ordering}
      end
    end

    class ByLastSubmissionDate < SortBy
      def self.order_by(ordering)
        {'last_assignment.submission.created_at': !ordering,
         'last_name': ordering,
         'first_name': ordering}
      end
    end
  end
end
