require 'spec_helper'

describe Submission do

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  describe do
    let(:submitter) { {
      uid: 'github|123456'
    } }
    let(:chapter) { {
      id: 'guide_chapter_id',
      name: 'guide_chapter_name'
    } }
    let(:parent) { {
      type: 'Lesson',
      name: 'A lesson name',
      position: '1',
      chapter: chapter
    } }
    let(:guide) { {
      slug: 'guide_slug',
      name: 'guide_name',
      parent: parent,
      language: {
        name: 'guide_language_name',
        devicon: 'guide_language_devicon'
      }
    } }
    let(:exercise) { {
      eid: 1,
      name: 'exercise_name',
      number: 1
    } }
    let(:submission) { {
      sid: '1',
      status: 'passed',
      result: 'result',
      content: 'find f = head.filter f',
      feedback: 'feedback',
      created_at: '2016-01-01 00:00:00',
      test_results: ['test_results'],
      submissions_count: 1,
      expectation_results: []
    } }
    let(:atheneum_submission) { submission.merge({
                                                   organization: 'example',
                                                   submitter: submitter,
                                                   exercise: exercise,
                                                   guide: guide
                                                 }) }

    describe 'when new submission is consumed' do

      context 'and student is no registered to a course' do
        it { expect { Submission.process!(atheneum_submission) }
               .to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'and student is registered to a course' do
        let(:guide_progress) { GuideProgress.where(organization: 'example', course: 'example/course1').sort(created_at: :asc).as_json }
        let(:exercise_progress) { Assignment.where(organization: 'example', course: 'example/course1').sort(created_at: :asc).as_json }
        let(:student) { {uid: 'github|123456', first_name: 'Jon', last_name: 'Doe', image_url: 'http://mumuki.io/logo.png', email: 'jondoe@gmail.com', name: 'jondoe'} }

        before { Student.create!(student.merge(organization: 'example', course: 'example/course1')) }
        before { Student.create!(student.merge(organization: 'example', course: 'example/course2', detached: true)) }
        before { Submission.process!(atheneum_submission) }

        context 'and is the first exercise submission' do
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.as_json).to json_like({guide: guide,
                                                                  student: student,
                                                                  organization: 'example',
                                                                  course: 'example/course1',
                                                                  stats: {
                                                                    passed: 1,
                                                                    failed: 0,
                                                                    passed_with_warnings: 0,
                                                                  },
                                                                  last_assignment: {
                                                                    exercise: exercise,
                                                                    submission: submission
                                                                  }}, except_fields) }
          it { expect(exercise_progress.size).to eq 1 }
          it { expect(exercise_progress.first.as_json).to json_like({guide: guide,
                                                                     organization: 'example',
                                                                     course: 'example/course1',
                                                                     student: student,
                                                                     exercise: exercise,
                                                                     submissions: [submission]}, except_fields) }
        end
        context 'and is the second exercise submission' do
          let(:submission2) { submission.merge({
                                                 sid: '2',
                                                 status: 'failed',
                                                 content: 'find = (.) head filter',
                                                 created_at: '2016-01-01 00:00:01'
                                               }) }
          let(:atheneum_submission2) { submission2.merge({
                                                           organization: 'example',
                                                           submitter: submitter,
                                                           exercise: exercise,
                                                           guide: guide.merge(chapter: chapter)
                                                         }) }
          before { Submission.process!(atheneum_submission2) }
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.as_json).to json_like({guide: guide,
                                                                  organization: 'example',
                                                                  course: 'example/course1',
                                                                  student: student,
                                                                  stats: {
                                                                    passed: 0,
                                                                    failed: 1,
                                                                    passed_with_warnings: 0,
                                                                  },
                                                                  last_assignment: {
                                                                    exercise: exercise,
                                                                    submission: submission2
                                                                  }}, except_fields) }
          it { expect(exercise_progress.size).to eq 1 }
          it { expect(exercise_progress.first.as_json).to json_like({guide: guide,
                                                                     organization: 'example',
                                                                     course: 'example/course1',
                                                                     student: student,
                                                                     exercise: exercise,
                                                                     submissions: [submission, submission2]}, except_fields) }

        end
        context 'and is the second exercise submission' do
          let(:exercise2) { {eid: 2, name: 'exercise_name2', number: 2} }
          let(:submission2) { submission.merge({
                                                 sid: '2',
                                                 status: 'passed_with_warnings',
                                                 content: 'find f = head . filter ((==True).f)',
                                                 created_at: '2016-01-01 00:00:01'
                                               }) }
          let(:atheneum_submission2) { submission2.merge({
                                                           organization: 'example',
                                                           submitter: submitter,
                                                           exercise: exercise2,
                                                           guide: guide.merge(chapter: chapter)
                                                         }) }
          before { Submission.process!(atheneum_submission2) }
          it { expect(guide_progress.size).to eq 1 }
          it { expect(guide_progress.first.as_json).to json_like({guide: guide,
                                                                  organization: 'example',
                                                                  course: 'example/course1',
                                                                  student: student,
                                                                  stats: {
                                                                    passed: 1,
                                                                    failed: 0,
                                                                    passed_with_warnings: 1,
                                                                  },
                                                                  last_assignment: {
                                                                    exercise: exercise2,
                                                                    submission: submission2
                                                                  }}, except_fields) }
          it { expect(exercise_progress.size).to eq 2 }
          it { expect(exercise_progress.first.as_json).to json_like({guide: guide,
                                                                     organization: 'example',
                                                                     course: 'example/course1',
                                                                     student: student,
                                                                     exercise: exercise,
                                                                     submissions: [submission]}, except_fields) }
          it { expect(exercise_progress.second.as_json).to json_like({guide: guide,
                                                                      organization: 'example',
                                                                      course: 'example/course1',
                                                                      student: student,
                                                                      exercise: exercise2,
                                                                      submissions: [submission2]}, except_fields) }
        end
      end

    end

    describe 'process submission without chapter' do
      let(:submission_without_chapter) { submission.merge({
                                                            organization: 'example',
                                                            submitter: submitter,
                                                            exercise: exercise,
                                                            parent: parent.delete(:chapter),
                                                            guide: guide
                                                          }) }
      
      let(:student) { {uid: 'github|123456', first_name: 'Jon', last_name: 'Doe', image_url: 'http://mumuki.io/logo.png', email: 'jondoe@gmail.com', name: 'jondoe'} }

      let(:guide_fetched) { Guide.first.as_json }

      before { Student.create!(student.merge(organization: 'example', course: 'example/course1')) }
      before { Submission.process!(submission_without_chapter) }

      it { expect(guide_fetched).to json_like(submission_without_chapter[:guide].merge(organization: 'example', course: 'example/course1'), except_fields) }

    end

  end

end
