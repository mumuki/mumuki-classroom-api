require 'spec_helper'

describe Course do

  let(:except_fields) { {except: [:created_at, :updated_at, :_id]} }

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      let(:course) { {name: 'foo', slug: 'test/foo', description: 'baz', organization: 'example.org'} }
      before { Course.create!(course) }
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({courses: [course]}, except_fields) }
    end
  end

  describe 'post /courses' do
    let(:course) { {code: 'K2001',
                    days: %w(monday saturday),
                    period: '2016',
                    shifts: ['morning'],
                    description: 'haskell',
                    organization: 'example.org',
                    slug: 'example.org/2016-K2001'} }
    let(:created_slug) { Course.last.slug }

    context 'when is normal teacher' do
      context 'rejects course creation' do
        before { header 'Authorization', build_auth_header('test/my-course') }
        before { post '/courses', course.to_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Course.count).to eq 0 }
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example.org/*') }
      before { post '/courses', course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example.org/2016-K2001' }

      context 'and when trying to create a duplicate' do
        before { post '/courses', course.to_json }

        it { expect(last_response.status).to be 409 }
        it { expect(last_response.body).to json_eq error: 'An entity with the same slug already exists' }
      end
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example.org/2016-K2001' }
    end

    context 'when course already exists' do
      before { Course.create! course }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course.to_json }

      it { expect(Course.count).to eq 1 }
      it { expect(last_response).to_not be_ok }
      it { expect(last_response.status).to eq 422 }
    end

    context 'create course does not create invitation link' do
      let(:created) { Course.create! course }

      it { expect(created.invitation).to be nil }
    end

    context 'create invitation link to existing course' do
      let(:time) { Time.now + 10.minutes }
      let(:created) { Course.create! course }
      let(:invitation) { created.invitation_link! time }

      it { expect(invitation).to be_truthy }
      it { expect(invitation.expiration_date).to eq time }
      it { expect(invitation.course_slug).to eq created.slug }
      it { expect(invitation.code.length).to eq 6 }
    end

    context 'should not create invitation link if already exists and is not expired' do
      let(:time) { Time.now + 10.minutes }
      let(:created) { Course.create!(course) }
      let(:invitation) { created.invitation_link! time }
      let(:invitation2) { created.invitation_link! time + 20.minutes }

      it { expect(invitation.code).to eq invitation2.code }
      it { expect(invitation.course_slug).to eq invitation2.course_slug }
      it { expect(invitation.expiration_date).to eq invitation2.expiration_date }
    end

    context 'should not create invitation link if expired date is in past' do
      let!(:time) { Time.now }

      let(:created) { Course.create!(course) }
      let(:invitation) { created.invitation_link! time - 10 }

      it { expect { invitation }.to raise_exception }
    end
  end

  describe 'get courses/:course/progress' do
    let(:exercise_progress) { {student: {uid: '1'}, guide: {slug: 'foo/bar'}, exercise: {eid: 1}} }
    before { Assignment.create! exercise_progress.merge(organization: 'example.org', course: 'example.org/foo') }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/progress' }
    it { expect(last_response.body).to json_like({exercise_student_progress: [exercise_progress.merge(organization: 'example.org', course: 'example.org/foo')]}, except_fields) }
  end

  describe 'get courses/:course/report' do
    let(:student) { {
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
          language: {
            name: 'javascript'
          },
          parent: {
            type: 'Exam',
            name: 'Exam Test'
          }
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
    } }
    before { Student.create! student }
    before { Student.create! student.merge uid: 'bar@baz.com', email: 'bar@baz.com', personal_id: '9191', stats: {failed: 27, passed: 100, passed_with_warnings: 2} }
    before { Student.create! student.merge uid: 'baz@bar.com', email: 'baz@bar.com', personal_id: '1212', stats: {failed: 27, passed: 120, passed_with_warnings: 2} }
    before { Student.create! student.merge first_name: 'Bar', uid: 'bar@foo.com', email: 'bar@foo.com', personal_id: '2222', stats: {failed: 27, passed: 120, passed_with_warnings: 1} }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/report' }
    it do
      expect(last_response.body).to eq <<TEST
last_name,first_name,email,personal_id,created_at,last_submission_date,passed_count,passed_with_warnings_count,failed_count,last_lesson_type,last_lesson_name,last_exercise_number,last_exercise_name,last_chapter
Bar,Foo,baz@bar.com,1212,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,2,27,Exam,Exam Test,1,Test
Bar,Bar,bar@foo.com,2222,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,1,27,Exam,Exam Test,1,Test
Bar,Foo,foo@bar.com,1234,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,117,1,27,Exam,Exam Test,1,Test
Bar,Foo,bar@baz.com,9191,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,100,2,27,Exam,Exam Test,1,Test
TEST
    end
  end

end
