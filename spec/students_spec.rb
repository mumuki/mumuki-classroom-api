require 'spec_helper'

describe Mumuki::Classroom::Student, workspaces: [:organization, :courses] do

  let(:course) { Course.locate! 'example.org/foo' }
  let(:date) { Time.now }

  let(:except_fields) { {except: [:created_at, :updated_at, :page, :total]} }

  let(:student1) { {uid: 'github|123456', first_name: 'Dorothy', last_name: 'Doe', email: 'dorodoe@mail.com'} }
  let(:student2) { {uid: 'twitter|123456', first_name: 'John', last_name: 'Doe', email: 'jdoe@mail.com'} }

  let(:guide1) { {slug: 'foo/bar'} }
  let(:guide2) { {slug: 'bar/baz'} }

  let(:guide_student_progress1) { {guide: guide1, student: student1} }
  let(:guide_student_progress2) { {guide: guide2, student: student1} }
  let(:guide_student_progress3) { {guide: guide2, student: student2} }

  let(:exercise1) { {
    guide: guide1,
    student: student1,
    exercise: {id: 1},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed', created_at: date + 2.minutes},
      {status: 'failed', created_at: date + 1.minute}
    ]
  } }
  let(:exercise2) { {
    guide: guide1,
    student: student1,
    exercise: {id: 2},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed', created_at: date + 1.minute},
      {status: 'failed', created_at: date + 2.minutes}
    ]
  } }
  let(:exercise3) { {
    guide: guide2,
    student: student1,
    exercise: {id: 3},
    submissions: [
      {status: 'passed', created_at: date}
    ]
  } }
  let(:exercise4) { {
    guide: guide2,
    student: student2,
    exercise: {id: 4},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed_with_warnings', created_at: date + 2.minutes}
    ]
  } }

  let(:example_students) {
    -> (student) {
      new_student = student.merge(organization: 'example.org', course: 'example.org/example')
      Mumuki::Classroom::Student.create! new_student
    }
  }

  let(:students) { Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/example') }

  let(:example_student_progresses) {
    -> (exercise) {
      Mumuki::Classroom::Assignment.create! exercise.merge(organization: 'example.org', course: 'example.org/example')
    }
  }

  let(:example_guide_student_progresses) {
    -> (guide_progress) {
      Mumuki::Classroom::GuideProgress.create! guide_progress.merge organization: 'example.org', course: 'example.org/example'
    }
  }

  describe do

    before { example_students.call student1 }
    before { example_students.call student2 }

    before { example_student_progresses.call exercise1 }
    before { example_student_progresses.call exercise2 }
    before { example_student_progresses.call exercise3 }
    before { example_student_progresses.call exercise4 }

    describe '#report' do
      let(:report) { Mumuki::Classroom::Student.report({organization: 'example.org', course: 'example.org/example'}) }
      it { expect(report.count).to eq 2 }
      it { expect(report.first).to json_like({first_name: 'Dorothy'}, except_fields) }
      it { expect(report.second).to json_like({first_name: 'John'}, except_fields) }
    end

    context 'if no students stats processed' do
      it { expect(students.size).to eq 2 }
      it { expect(students.first.as_json).to json_like student1.merge(organization: 'example.org', course: 'example.org/example'), except_fields }
      it { expect(students.second.as_json).to json_like student2.merge(organization: 'example.org', course: 'example.org/example'), except_fields }
    end

    context 'if students stats processed' do
      before { Mumuki::Classroom::Student.update_all_stats(organization: 'example.org', course: 'example.org/example') }

      it { expect(students.size).to eq 2 }
      it { expect(students.second.as_json).to json_like(student2.merge(stats: {passed: 0, passed_with_warnings: 1, failed: 0}, organization: 'example.org', course: 'example.org/example'), except_fields) }
      it { expect(students.first.as_json).to json_like(student1.merge(stats: {passed: 2, passed_with_warnings: 0, failed: 1}, organization: 'example.org', course: 'example.org/example'), except_fields) }
    end

    context 'delete student from students' do

      let(:students) { Mumuki::Classroom::Student.where organization: 'example.org', course: 'example.org/example' }
      let(:guide_students_progress) { Mumuki::Classroom::GuideProgress.where(organization: 'example.org', course: 'example.org/example').as_json }
      let(:exercise_student_progress) { example_student_progresses.all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { example_guide_student_progresses.call guide_student_progress1 }
      before { example_guide_student_progresses.call guide_student_progress2 }
      before { example_guide_student_progresses.call guide_student_progress3 }

      before { Mumuki::Classroom::Student.find_by!(uid: 'github|123456').destroy_cascade! }

      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(Mumuki::Classroom::Assignment.count).to eq 1 }
    end

  end

  describe 'students routes' do

    describe 'get /courses/:course/students' do

      let(:student) { {email: 'foobar@gmail.com', uid: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', personal_id: '1'} }
      let(:student2) { {email: 'bazlol@gmail.com', uid: 'bazlol@gmail.com', first_name: 'baz', last_name: 'lol', personal_id: '2'} }
      let(:student_saved) { {organization: 'example.org', course: 'example.org/foo'}.merge student }
      let(:student_saved2) { {organization: 'example.org', course: 'example.org/foo'}.merge student2 }
      let(:follower) { {organization: 'example.org', course: 'example.org/foo',
                        email: 'a.teacher@gmail.com', uids: [student[:uid]]} }

      context 'when guides already exists in a course' do
        before { Mumuki::Classroom::Student.create! student.merge(organization: 'example.org', course: 'example.org/foo') }
        before { Mumuki::Classroom::Student.create! student.merge(organization: 'example.org', course: 'example.org/test') }
        before { Mumuki::Classroom::Student.create! student2.merge(organization: 'example.org', course: 'example.org/foo') }
        before { Mumuki::Classroom::Student.create! student2.merge(organization: 'example.org', course: 'example.org/test') }
        before { Mumuki::Classroom::Follower.create! follower }

        context 'get students with auth0 client' do
          before { header 'Authorization', build_auth_header('*') }
          before { get '/courses/foo/students' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved, student_saved2]}, except_fields) }
        end
        context 'get students with auth client' do
          before { header 'Authorization', build_auth_header('*') }
          before { get '/api/courses/foo/students?personal_id=2&uid=bazlol@gmail.com' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved2]}, except_fields) }
        end
        context 'get all students' do
          before { header 'Authorization', build_auth_header('*', 'a.teacher@gmail.com') }
          before { get '/courses/foo/students?students=all' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved, student_saved2]}, except_fields) }
        end
        context 'get following students with auth client' do
          before { header 'Authorization', build_auth_header('*', 'a.teacher@gmail.com') }
          before { get '/courses/foo/students?students=follow' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved]}, except_fields) }
        end
      end

    end
  end

  describe 'get /courses/:course/student/:uid' do
    before { header 'Authorization', build_auth_header('*') }
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:json) { {student: student.merge(uid: 'auth0|1'), course: {slug: 'example.org/foo'}} }
    let(:created_at) { 'created_at' }
    before { Mumuki::Classroom::Student.create!(student.merge(uid: 'auth0|1', organization: 'example.org', course: 'example.org/foo')) }
    before { get '/courses/foo/student/auth0%7c1' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_like student.merge({organization: 'example.org', course: 'example.org/foo', uid: 'auth0|1'}), except_fields }
  end

  describe 'post /courses/:course/students/:student_id' do
    let(:created_user) { User.locate! 'github|123456' }

    before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', uid: 'github|123456', tenant: 'example.org') }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/students/github%7C123456' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_eq status: :created }
    it { expect(created_user.first_name).to eq created_user.verified_first_name }
    it { expect(created_user.last_name).to eq created_user.verified_last_name }
  end

  describe 'put /courses/:course/students/:student_id' do
    let(:updated_user) { User.locate! 'jondoe@gmail.com' }

    before { create :user, first_name: 'Jon', last_name: 'Din', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', permissions: {student: 'example.org/*'} }
    before { Mumuki::Classroom::Student.create! first_name: 'Jon', last_name: 'Din', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo', organization: 'example.org', course: 'example.org/foo' }
    before { header 'Authorization', build_auth_header('*') }

    context "when passing complete data" do
      before { put '/courses/foo/students/jondoe@gmail.com', {first_name: 'John', last_name: 'Doe', email: 'jondoe@gmail.com'}.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: :updated }
      it { expect(Mumuki::Classroom::Student.find_by(uid: 'jondoe@gmail.com').last_name).to eq 'Doe' }
      it { expect(updated_user.first_name).to eq updated_user.verified_first_name }
      it { expect(updated_user.last_name).to eq updated_user.verified_last_name }
    end

    context "when passing incomplete data" do
      before { put '/courses/foo/students/jondoe@gmail.com', {last_name: 'Doe'}.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(last_response.body['message']).to include("First name can't be blank, Email can't be blank") }
      it { expect(Mumuki::Classroom::Student.find_by(uid: 'jondoe@gmail.com').last_name).to eq 'Din' }
      it { expect(updated_user.first_name).to eq 'Jon' }
      it { expect(updated_user.last_name).to eq 'Din' }
    end
  end

  describe 'when needs mumuki-user' do
    let(:fetched_student) { Mumuki::Classroom::Student.find_by(uid: 'github|123456') }
    let(:user) { User.locate! 'github|123456' }
    let(:janitor) { create :user, uid: 'janitor@mumuki.org', permissions: { janitor: '*/*' } }

    describe 'post /courses/:course/students/:student_id/detach' do

      before { create :user, example_students.call(student1).as_user }

      context 'should be detached' do
        before { header 'Authorization', build_auth_header('example.org/*', janitor.uid) }

        context 'user solved any exercises' do
          before { post '/courses/example/students/github%7C123456/detach' }
          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_eq status: :updated }
          it { expect(fetched_student.detached).to eq true }
          it { expect(fetched_student.detached_at).not_to be nil }
          it { expect(user.reload.student_of? 'example.org/example').to eq false }
          it { expect(user.reload.ex_student_of? 'example.org/example').to eq false }
        end

        context 'user doesn\'t solve any exercises' do
          before { create :assignment, submitter: user, organization: Organization.locate!('example.org') }
          before { post '/courses/example/students/github%7C123456/detach' }
          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_eq status: :updated }
          it { expect(fetched_student.detached).to eq true }
          it { expect(fetched_student.detached_at).not_to be nil }
          it { expect(user.reload.student_of? 'example.org/example').to eq false }
          it { expect(user.reload.ex_student_of? 'example.org/example').to eq true }
        end
      end

    end

    describe 'post /courses/:course/students/:student_id/attach' do

      before { example_students.call student1.merge(detached: true, detached_at: Time.now) }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example.org/*') }
        before { post '/courses/example/students/github%7C123456/attach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.detached).to eq nil }
        it { expect(fetched_student.detached_at).to eq nil }
      end

    end

    describe 'post /courses/:course/students/:student_id/transfer' do

      before { example_students.call student1 }
      before { example_student_progresses.call exercise1 }
      before { example_student_progresses.call exercise2 }
      before { example_guide_student_progresses.call guide_student_progress1 }
      before { example_guide_student_progresses.call guide_student_progress2 }

      let(:fetched_guide_progresses) { Mumuki::Classroom::GuideProgress.where('student.uid': student1[:uid]).order(created_at: :asc).to_a }
      let(:fetched_assignments) { Mumuki::Classroom::Assignment.where('student.uid': student1[:uid]).to_a }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('*/*') }
        before { post '/courses/example/students/github%7C123456/transfer', {destination: 'some_course'}.to_json }

        let(:only_fields) { {only: [:organization, :course]} }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.organization).to eq 'example.org' }
        it { expect(fetched_student.course).to eq 'example.org/some_course' }

        it { expect(fetched_guide_progresses.count).to eq 2 }
        it { expect(fetched_guide_progresses.first.as_json).to json_like({organization: 'example.org', course: 'example.org/some_course'}, only_fields) }
        it { expect(fetched_assignments.count).to eq 2 }
        it { expect(fetched_assignments.first.as_json).to json_like({organization: 'example.org', course: 'example.org/some_course'}, only_fields) }
      end

    end

    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        let!(:course) { create(:course, slug: 'example.org/bar') }

        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Mumuki::Classroom::Student.count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish in resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Mumuki::Classroom::Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
              it { expect(User.find_by(uid: student[:email])).to json_like student, only: student.keys }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example.org', course: 'example.org/foo'), except_fields) }
            end
          end
          context 'add student to a course if exists' do
            before { post '/courses/foo/students', student_json }
            context 'in same course, should fails' do
              before { expect(Mumukit::Nuntius).to_not receive(:notify!) }
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(existing_members: [student[:email]]) }
            end
            context 'in different course, should work' do
              let!(:course) { create(:course, slug: 'example.org/bar') }
              before { header 'Authorization', build_auth_header('*', 'auth1') }
              before { post '/courses/bar/students', student_json }

              it { expect(last_response).to be_ok }
              it { expect(last_response.status).to eq 200 }
              it { expect(last_response.body).to json_eq(status: 'created') }
            end
          end
        end
      end

      context 'when course does not exist' do
        before { expect(Mumukit::Nuntius).to_not receive(:notify!) }

        it 'rejects creating a student' do
          header 'Authorization', build_auth_header('*')

          post '/courses/bar/students', student_json

          expect(last_response).to_not be_ok
          expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/bar').count).to eq 0
        end
      end
    end

    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo', personal_id: '1234'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish in resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Mumuki::Classroom::Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example.org', course: 'example.org/foo'), except_fields) }
            end
            context 'and user does not exist' do
              let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo'} }
              let(:created_course_student) { Mumuki::Classroom::Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example.org', course: 'example.org/foo'), except_fields) }
            end
          end
          context 'should not publish in resubmissions queue' do
            before { post '/courses/foo/students', student_json }
            before { expect(Mumukit::Nuntius).to_not receive(:notify!) }
            context 'and user already exists by uid' do
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(existing_members: [student[:email]]) }
            end
            context 'and user already exists by email' do
              before { header 'Authorization', build_auth_header('*', 'auth1') }
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(existing_members: [student[:email]]) }
            end
          end
        end

      end

      context 'when course does not exist' do
        before { expect(Mumukit::Nuntius).to_not receive(:notify!) }

        it 'rejects creating a student' do
          header 'Authorization', build_auth_header('*')

          post '/courses/bar/students', student_json

          expect(last_response).to_not be_ok
          expect(Mumuki::Classroom::Student.where(organization: 'example.org', course: 'example.org/bar').count).to eq 0
        end
      end
    end
  end

  describe 'students routes with params' do

    describe 'get /courses/:course/students' do

      let(:except_fields) { {except: [:created_at, :updated_at]} }

      let(:student1) do
        {
          uid: 'foobar@gmail.com',
          email: 'foobar@gmail.com',
          first_name: 'foo',
          last_name: 'bar',
          organization: 'example.org',
          course: 'example.org/foo'
        }
      end
      let(:student2) do
        {
          uid: 'jondoe@gmail.com',
          email: 'jondoe@gmail.com',
          first_name: 'jon',
          last_name: 'doe',
          organization: 'example.org',
          course: 'example.org/foo'
        }
      end
      let(:student3) do
        {
          uid: 'walter@gmail.com',
          email: 'walter@gmail.com',
          first_name: 'wal',
          last_name: 'ter',
          organization: 'example.org',
          course: 'example.org/foo'
        }
      end
      let(:student4) do
        {
          uid: 'zzztop@gmail.com',
          email: 'zzztop@gmail.com',
          first_name: 'zzz',
          last_name: 'top',
          organization: 'example.org',
          course: 'example.org/foo',
          detached: true
        }
      end

      before { Mumuki::Classroom::Student.create! student1 }
      before { Mumuki::Classroom::Student.create! student2 }
      before { Mumuki::Classroom::Student.create! student3 }
      before { Mumuki::Classroom::Student.create! student4 }

      before { header 'Authorization', build_auth_header('*') }

      context 'with default values' do
        before { get '/courses/foo/students' }
        it { expect(last_response.body).to json_like({page: 1, students: [student1, student2, student3], total: 3}, except_fields) }
      end

      context 'with specific page' do
        before { get '/courses/foo/students?page=2' }
        it { expect(last_response.body).to json_like({page: 2, students: [], total: 3}, except_fields) }
      end

      context 'with specific page and items per page' do
        before { get '/courses/foo/students?page=2&per_page=1' }
        it { expect(last_response.body).to json_like({page: 2, students: [student2], total: 3}, except_fields) }
      end

      context 'with name descending sort and detached' do
        before { get '/courses/foo/students?with_detached=true&sort_by=name&order_by=desc' }
        it { expect(last_response.body).to json_like({page: 1, students: [student4], total: 1}, except_fields) }
      end

      context 'with query filter' do
        before { get '/courses/foo/students?q="foo"' }
        it { expect(last_response.body).to json_like({page: 1, students: [student1], total: 1}, except_fields) }
      end

    end
  end

  describe 'get students/report' do
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
            name: 'Exam Test',
            chapter: {
              name: 'Test Chapter'
            }
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
    before { Mumuki::Classroom::Student.create! student }
    before { Mumuki::Classroom::Student.create! student.merge uid: 'bar@baz.com', email: 'bar@baz.com', personal_id: '9191', stats: {failed: 27, passed: 100, passed_with_warnings: 2} }
    before { Mumuki::Classroom::Student.create! student.merge uid: 'baz@bar.com', email: 'baz@bar.com', personal_id: '1212', stats: {failed: 27, passed: 120, passed_with_warnings: 2}, course: 'example.org/bar' }
    before { Mumuki::Classroom::Student.create! student.merge first_name: 'Bar', uid: 'bar@foo.com', email: 'bar@foo.com', personal_id: '2222', stats: {failed: 27, passed: 120, passed_with_warnings: 1}, course: 'example.org/bar' }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/students/report' }
    it do
      expect(last_response.body).to eq <<TEST
last_name,first_name,email,personal_id,detached,created_at,last_submission_date,passed_count,passed_with_warnings_count,failed_count,last_lesson_type,last_lesson_name,last_exercise_number,last_exercise_name,last_chapter,course
Bar,Foo,baz@bar.com,1212,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,2,27,Exam,Exam Test,1,Test,Test Chapter,example.org/bar
Bar,Bar,bar@foo.com,2222,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,120,1,27,Exam,Exam Test,1,Test,Test Chapter,example.org/bar
Bar,Foo,foo@bar.com,1234,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,117,1,27,Exam,Exam Test,1,Test,Test Chapter,example.org/foo
Bar,Foo,bar@baz.com,9191,false,2016-08-01T18:39:57.000Z,2016-08-01T18:39:57.481Z,100,2,27,Exam,Exam Test,1,Test,Test Chapter,example.org/foo
TEST
    end
  end

end
