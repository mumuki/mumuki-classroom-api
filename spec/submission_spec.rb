require 'spec_helper'

describe Classroom::Submission do

  after do
    Classroom::Database.clean!
  end

  describe do
    let(:submitter) {{
      uid: 'github|123456'
    }}
    let(:chapter) {{
      id: 'guide_chapter_id',
      name: 'guide_chapter_name'
    }}
    let(:parent) {{
      type: 'Lesson',
      name: 'A lesson name',
      position: '1',
      chapter: chapter
    }}
    let(:guide) {{
      slug: 'guide_slug',
      name: 'guide_name',
      parent: parent,
      language: {
        name: 'guide_language_name',
        devicon: 'guide_language_devicon'
      }
    }}
    let(:exercise) {{
      id: 1,
      name: 'exercise_name',
      number: 1
    }}
    let(:submission) {{
      id: 1,
      status: 'passed',
      result: 'result',
      content: 'find f = head.filter f',
      feedback: 'feedback',
      created_at: '2016-01-01 00:00:00',
      test_results: 'test_results',
      submissions_count: 1,
      expectation_results: []
    }}
    let(:atheneum_submission) { submission.merge({
      submitter: submitter,
      exercise: exercise,
      guide: guide
    })}

    describe 'when new submission is consumed' do

      context 'and student is no registered to a course' do
        it { expect {Classroom::Submission.process!(atheneum_submission)}
               .to raise_error(Mumukit::Service::DocumentNotFoundError) }
      end

      context 'and student is registered to a course' do
        let(:guide_progress) { Classroom::Collection::GuideStudentsProgress.for('course1').all.as_json[:guide_students_progress] }
        let(:exercise_progress) { Classroom::Collection::ExerciseStudentProgress.for('course1').all.as_json[:exercise_student_progress] }
        let(:course_student) {{ course: {slug: 'example/course1'}, student: submitter }}
        let(:student) {{ uid: 'github|123456', first_name: 'Jon', last_name: 'Doe', image_url: 'http://mumuki.io/logo.png', email: 'jondoe@gmail.com', name: 'jondoe' }}

        before { Classroom::Collection::Students.for('course1').insert! student.wrap_json }
        before { Classroom::Collection::CourseStudents.insert! course_student.wrap_json }
        before { Classroom::Submission.process!(atheneum_submission) }

        context 'and is the first exercise submission' do
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                      student: student,
                                                                      stats: {
                                                                        passed: 1,
                                                                        failed: 0,
                                                                        passed_with_warnings: 0,
                                                                      },
                                                                      last_assignment: {
                                                                        exercise: exercise,
                                                                        submission: submission
                                                                      }) }
          it { expect(exercise_progress.size).to eq 1 }
          it { expect(exercise_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                         student: student,
                                                                         exercise: exercise,
                                                                         submissions: [submission]) }
        end
        context 'and is the second exercise submission' do
          let(:submission2) { submission.merge({
            id: 2,
            status: 'failed',
            content: 'find = (.) head filter',
            created_at: '2016-01-01 00:00:01'
          })}
          let(:atheneum_submission2) { submission2.merge({
            submitter: submitter,
            exercise: exercise,
            guide: guide.merge(chapter: chapter)
          })}
          before { Classroom::Submission.process!(atheneum_submission2) }
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                      student: student,
                                                                      stats: {
                                                                        passed: 0,
                                                                        failed: 1,
                                                                        passed_with_warnings: 0,
                                                                      },
                                                                      last_assignment: {
                                                                        exercise: exercise,
                                                                        submission: submission2
                                                                      }) }
          it { expect(exercise_progress.size).to eq 1 }
          it { expect(exercise_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                         student: student,
                                                                         exercise: exercise,
                                                                         submissions: [submission, submission2]) }

        end
        context 'and is the second exercise submission' do
          let(:exercise2) {{ id: 2, name: 'exercise_name2', number: 2 }}
          let(:submission2) { submission.merge({
            id: 2,
            status: 'passed_with_warnings',
            content: 'find f = head . filter ((==True).f)',
            created_at: '2016-01-01 00:00:01'
          })}
          let(:atheneum_submission2) { submission2.merge({
            submitter: submitter,
            exercise: exercise2,
            guide: guide.merge(chapter: chapter)
          })}
          before { Classroom::Submission.process!(atheneum_submission2) }
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                      student: student,
                                                                      stats: {
                                                                        passed: 1,
                                                                        failed: 0,
                                                                        passed_with_warnings: 1,
                                                                      },
                                                                      last_assignment: {
                                                                        exercise: exercise2,
                                                                        submission: submission2
                                                                      }) }
          it { expect(exercise_progress.size).to eq 2 }
          it { expect(exercise_progress.first.deep_symbolize_keys).to eq(guide: guide,
                                                                         student: student,
                                                                         exercise: exercise,
                                                                         submissions: [submission]) }
          it { expect(exercise_progress.second.deep_symbolize_keys).to eq(guide: guide,
                                                                          student: student,
                                                                          exercise: exercise2,
                                                                          submissions: [submission2]) }
        end
      end

    end

    describe 'process submission without chapter' do
      let(:submission_without_chapter) { submission.merge({
        submitter: submitter,
        exercise: exercise,
        parent: parent.delete(:chapter),
        guide: guide
      })}

      let(:course_student) {{ course: {slug: 'example/course1'}, student: submitter }}
      let(:student) {{ uid: 'github|123456', first_name: 'Jon', last_name: 'Doe', image_url: 'http://mumuki.io/logo.png', email: 'jondoe@gmail.com', name: 'jondoe' }}

      let(:guide_fetched) { Classroom::Collection::Guides.for('course1').all.as_json[:guides].first }

      before { Classroom::Collection::Students.for('course1').insert! student.wrap_json }
      before { Classroom::Collection::CourseStudents.insert! course_student.wrap_json }
      before { Classroom::Submission.process!(submission_without_chapter) }

      it { expect(guide_fetched.to_json).to json_eq(submission_without_chapter[:guide]) }

    end

  end

end
