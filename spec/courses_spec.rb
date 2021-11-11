require 'spec_helper'

describe Course do

  let(:except_fields) { {except: [:created_at, :updated_at, :_id]} }
  let(:book) { create(:book) }
  let!(:organization) { create(:organization, name: 'example.org', book: book) }

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      let!(:course) { create(:course, slug: "#{organization.name}/awesome-code") }
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({courses: [course]}, except_fields) }
    end
  end

  describe 'post /courses' do
    let(:new_course) { {code: 'K2001',
                    days: %w(monday saturday),
                    period: '2016',
                    shifts: ['morning'],
                    description: 'haskell',
                    organization: 'example.org',
                    slug: 'example.org/2016-K2001'} }
    let(:new_course_slug) { new_course[:slug] }
    let(:created_slug) { Course.last.slug }

    context 'when is normal teacher' do
      context 'rejects course creation' do
        before { header 'Authorization', build_auth_header('test/my-course') }
        before { post '/courses', new_course.to_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Course.count).to eq 0 }
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example.org/*') }
      before { post '/courses', new_course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example.org/2016-K2001' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', new_course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example.org/2016-K2001' }
    end

    context 'when course already exists' do
      let!(:course) { create(:course, slug: new_course_slug) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', new_course.to_json }

      it { expect(Course.count).to eq 1 }
      it { expect(last_response).to_not be_ok }
      it { expect(last_response.status).to eq 400 } #RecordInvalid
    end

    context 'create course does not create invitation link' do
      let(:course) { create(:course, slug: "#{organization.name}/awesome-code") }

      it { expect(course.current_invitation).to be nil }
    end

    context 'create invitation link to existing course' do
      let(:time) { 10.minutes.since }
      let(:course) { create(:course, slug: "#{organization.name}/awesome-code") }
      let(:invitation) { course.invite! time }

      it { expect(invitation).to be_truthy }
      it { expect(invitation.expiration_date).to be_within(1.second).of time }
      it { expect(invitation.course_slug).to eq course.slug }
      it { expect(invitation.code.length).to eq 6 }
    end

    context 'should not create invitation link if already exists and is not expired' do
      let(:time) { 10.minutes.since }
      let(:course) { create(:course, slug: "#{organization.name}/awesome-code") }
      let(:invitation) { course.invite! time }
      let(:invitation2) { course.invite! time + 20.minutes }

      it { expect(invitation.code).to eq invitation2.code }
      it { expect(invitation.course_slug).to eq invitation2.course_slug }
      it { expect(invitation.expiration_date).to be_within(1.second).of invitation2.expiration_date }
    end

    context 'should not create invitation link if expired date is in the past' do
      let(:time) { DateTime.current }
      let(:course) { create(:course, slug: "#{organization.name}/awesome-code") }

      let(:invitation) { course.invite!(time - 2.minutes) }

      it { expect(invitation).to be_nil }
    end

    context 'should forbid creating course if organization does not exist' do
      before { header 'Authorization', build_auth_header('*') }
      before { organization.destroy! }
      before { post '/courses', new_course.merge(organization: 'foobar').to_json }

      it { expect(Course.count).to eq 0 }
      it { expect(last_response).to_not be_ok }
      it { expect(last_response.status).to eq 404 }
    end
  end

  describe 'get courses/:course/progress' do
    let(:exercise_progress) { {student: {uid: '1'}, guide: {slug: 'foo/bar'}, exercise: {eid: 1}} }
    before { Mumuki::Classroom::Assignment.create! exercise_progress.merge(organization: 'example.org', course: 'example.org/foo') }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/progress' }
    it { expect(last_response.body).to json_like({exercise_student_progress: [exercise_progress.merge(organization: 'example.org', course: 'example.org/foo')]}, except_fields) }
  end

  describe 'get courses/:course/report' do
    let(:full_student) { {
      organization: 'example.org',
      course: 'example.org/foo',
      uid: 'foo@bar.com',
      created_at: '2016-08-01T18:39:57.000Z',
      email: 'foo@bar.com',
      personal_id: '1234',
      first_name: 'Foo',
      last_name: 'Bar',
      last_assignment: {
        exercise: {
          eid: 1,
          name: 'Test',
          number: 1,
        },
        guide: {
          name: 'Exam Test',
          slug: 'foo/bar',
          parent: {
            type: 'Exam',
            name: 'Exam Test',
            chapter: {
              name: 'Test Chapter'
            }
          },
          language: {
            name: 'javascript'
          },
        },
        submission: {
          created_at: '2016-08-01T18:39:57.481Z',
          sid: '6a6ea7df6e55fbba',
          status: 'failed'
        }
      },
      stats: {
        failed: 27,
        passed: 117,
        passed_with_warnings: 1
      }
    }}

    let(:student) { full_student }

    before { Mumuki::Classroom::Student.create! student }
    before { Mumuki::Classroom::Student.create! student.merge uid: 'bar@baz.com', email: 'bar@baz.com', personal_id: '9191', stats: {failed: 27, passed: 100, passed_with_warnings: 2} }
    before { Mumuki::Classroom::Student.create! student.merge uid: 'baz@bar.com', email: 'baz@bar.com', personal_id: '1212', stats: {failed: 27, passed: 120, passed_with_warnings: 2} }
    before { Mumuki::Classroom::Student.create! student.merge first_name: 'Bar', uid: 'bar@foo.com', email: 'bar@foo.com', personal_id: '2222', stats: {failed: 27, passed: 120, passed_with_warnings: 1} }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/report' }

    context 'when fields are complete' do
      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,personal_id,detached,created_at,last_submission_date,passed_count,passed_with_warnings_count,failed_count,last_lesson_type,last_lesson_name,last_exercise_number,last_exercise_name,last_chapter
Bar,Foo,baz@bar.com,1212,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,2,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Bar,bar@foo.com,2222,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,1,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Foo,foo@bar.com,1234,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,117,1,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Foo,bar@baz.com,9191,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,100,2,27,Exam,Exam Test,1,Test,Test Chapter
TEST
      end
    end

    context 'when fields aren\'t complete' do
      let(:student) { full_student.except(:personal_id) }
      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,personal_id,detached,created_at,last_submission_date,passed_count,passed_with_warnings_count,failed_count,last_lesson_type,last_lesson_name,last_exercise_number,last_exercise_name,last_chapter
Bar,Foo,baz@bar.com,1212,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,2,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Bar,bar@foo.com,2222,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,1,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Foo,foo@bar.com,,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,117,1,27,Exam,Exam Test,1,Test,Test Chapter
Bar,Foo,bar@baz.com,9191,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,100,2,27,Exam,Exam Test,1,Test,Test Chapter
TEST
      end
    end
  end
end
