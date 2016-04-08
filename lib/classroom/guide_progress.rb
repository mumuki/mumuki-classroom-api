module Classroom::GuideProgress
  extend Classroom::WithMongo

  class << self
    def collection_name
      'guides_progress'
    end

    def by_slug(slug)
      find('guide.slug' => slug)
    end

    def by_course_slug(slug)
      uniq('guide', { 'course.slug' => slug }, 'slug')
    end

    def guide_data(slug, course)
      find('course.slug' => course, 'guide.slug' => slug)
        .projection('guide' => 1, '_id' => 0).limit(1).first
    end

    def by_slug_and_course(slug, course)
      find('course.slug' => course, 'guide.slug' => slug)
        .projection('_id' => 0, 'guide' => 0, 'exercises.submissions' => {'$slice' => -1})
    end

    def students_by_course_slug(course)
      uniq('student', { 'course.slug' => course }, 'social_id')
    end

    def exercise_by_student(course_slug, slug, student_id, exercise_id)
      guide_progress = get_exercise slug, student_id, course_slug
      guide_progress.tap do |gp|
        gp['exercise'] = gp['exercises'].detect { |exercise| exercise['id'] == exercise_id }
        gp.delete 'exercises'
      end
    end

    def by_course(slug)
      by_course_slug slug
    end

    def all
      find
    end

    def update!(data)
      json = process_params(data).deep_symbolize_keys

      course_student = Classroom::CourseStudent.find_by('student.social_id' => json[:submitter][:social_id]).deep_symbolize_keys

      json[:submitter][:first_name] = course_student[:student][:first_name]
      json[:submitter][:last_name] = course_student[:student][:last_name]

      unless guide_exist? json
        create_guide! json
        return
      end

      if exercise_exist? json
        add_submission_to_exercise! json
      else
        create_exercise! json
      end
    end

    def exists?(id)
      by_id(id).count > 0
    end

    def process_params(data)
      params = {}
      params['guide'] = data['guide']
      params['submitter'] = data['submitter']
      params['course'] = course_for(data['submitter']['social_id'])

      params['exercise'] = {
        id: data['exercise']['id'],
        name: data['exercise']['name'],
        number: data['exercise']['number'],
        submission: {
          id: data['id'],
          status: data['status'],
          result: data['result'],
          expectation_results: data['expectation_results'],
          test_results: data['test_results'],
          feedback: data['feedback'],
          submissions_count: data['submissions_count'],
          created_at: data['created_at'],
          content: data['content']
        }
      }
      params.symbolize_keys
    end

    private

    def get_exercise(slug, student_id, course_slug)
      find('guide.slug' => slug, 'student.social_id' => student_id, 'course.slug' => course_slug).projection(_id: 0).first
    end

    def course_for(social_id)
      Classroom::CourseStudent.find_by('student.social_id' => social_id)['course']
    end

    def make_exercise_json(json)
      {id: json[:exercise][:id], name: json[:exercise][:name], number: json[:exercise][:number], submissions: [json[:exercise][:submission]]}
    end

    def make_exercise_query(json)
      make_guide_query(json).merge('exercises.id' => json[:exercise][:id])
    end

    def make_guide_query(json)
      {'guide.slug' => json[:guide][:slug], 'student.social_id' => json[:submitter][:social_id], 'course.slug' => json[:course][:slug]}
    end

    def guide_exist?(json)
      any? make_guide_query(json)
    end

    def exercise_exist?(json)
      any? make_exercise_query(json)
    end

    def create_guide!(submission_json)
      insert_one({guide: submission_json[:guide], student: submission_json[:submitter], course: submission_json[:course], exercises: [make_exercise_json(submission_json)]})
    end

    def create_exercise!(json)
      update_one(make_guide_query(json), {'$push' => {'exercises' => make_exercise_json(json)}})
    end

    def add_submission_to_exercise!(json)
      update_one(
        make_exercise_query(json),
        {'$push' => {'exercises.$.submissions' => json[:exercise][:submission]},
         '$set' => {'exercises.$.name' => json[:exercise][:name], 'exercises.$.number' => json[:exercise][:number]}})
    end
  end
end
