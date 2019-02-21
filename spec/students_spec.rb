require 'spec_helper'

describe Student do

  before { User.upsert_permissions! 'github|123456', {} }

  let(:date) { Time.now }

  let(:except_fields) { {except: [:created_at, :updated_at, :page, :total]} }

  let(:student1) { {uid: 'github|123456', first_name: 'Dorothy'} }
  let(:student2) { {uid: 'twitter|123456', first_name: 'John'} }

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
  let(:students) { Student.where(organization: 'example.org', course: 'example.org/example') }
  let(:create_student!) { -> (student) { Student.create!(student.merge(organization: 'example.org', course: 'example.org/example')) } }
  let(:create_assignment!) { -> (exercise) { Assignment.create! exercise.merge(organization: 'example.org', course: 'example.org/example') } }
  let(:create_student_guide_progress!) { -> (guide_progress) { GuideProgress.create! guide_progress.merge organization: 'example.org', course: 'example.org/example' } }

  describe do

    before { create_student!.call student1 }
    before { create_student!.call student2 }

    before { create_assignment!.call exercise1 }
    before { create_assignment!.call exercise2 }
    before { create_assignment!.call exercise3 }
    before { create_assignment!.call exercise4 }

    describe '#report' do
      let(:report) { Student.report({organization: 'example.org', course: 'example.org/example'}) }
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
      before { Student.update_all_stats(organization: 'example.org', course: 'example.org/example') }

      it { expect(students.size).to eq 2 }
      it { expect(students.second.as_json).to json_like(student2.merge(stats: {passed: 0, passed_with_warnings: 1, failed: 0}, organization: 'example.org', course: 'example.org/example'), except_fields) }
      it { expect(students.first.as_json).to json_like(student1.merge(stats: {passed: 2, passed_with_warnings: 0, failed: 1}, organization: 'example.org', course: 'example.org/example'), except_fields) }
    end

    context 'delete student from students' do

      let(:guides) { Guide.where organization: 'example.org', course: 'example.org/example' }
      let(:students) { Student.where organization: 'example.org', course: 'example.org/example' }
      let(:guide_students_progress) { GuideProgress.where(organization: 'example.org', course: 'example.org/example').as_json }
      let(:exercise_student_progress) { create_assignment!.all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { Guide.create! guide1.merge(organization: 'example.org', course: 'example.org/example') }
      before { Guide.create! guide2.merge(organization: 'example.org', course: 'example.org/example') }

      before { create_student_guide_progress!.call guide_student_progress1 }
      before { create_student_guide_progress!.call guide_student_progress2 }
      before { create_student_guide_progress!.call guide_student_progress3 }

      before { Student.find_by!(uid: 'github|123456').destroy_cascade! }

      it { expect(guides.size).to eq 1 }
      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(Assignment.count).to eq 1 }


    end

  end

  describe 'students routes' do

    describe 'get /courses/:course/students' do

      let(:student) { {email: 'foobar@gmail.com', uid: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', personal_id: '1'} }
      let(:student2) { {email: 'bazlol@gmail.com', uid: 'bazlol@gmail.com', first_name: 'baz', last_name: 'lol', personal_id: '2'} }
      let(:student_saved) { {organization: 'example.org', course: 'example.org/foo'}.merge student }
      let(:student_saved2) { {organization: 'example.org', course: 'example.org/foo'}.merge student2 }

      context 'when guides already exists in a course' do
        before { Student.create! student.merge(organization: 'example.org', course: 'example.org/foo') }
        before { Student.create! student.merge(organization: 'example.org', course: 'example.org/test') }
        before { Student.create! student2.merge(organization: 'example.org', course: 'example.org/foo') }
        before { Student.create! student2.merge(organization: 'example.org', course: 'example.org/test') }

        context 'get students with auth0 client' do
          before { header 'Authorization', build_auth_header('*') }
          before { get '/courses/foo/students' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved, student_saved2]}, except_fields) }
        end
        context 'get students with auth client' do
          before { header 'Authorization', build_mumuki_auth_header('*') }
          before { get '/api/courses/foo/students?personal_id=2&uid=bazlol@gmail.com' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved2]}, except_fields) }
        end
      end

    end
  end

  describe 'get /courses/:course/student/:uid' do
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:json) { {student: student.merge(uid: 'auth0|1'), course: {slug: 'example.org/foo'}} }
    let(:created_at) { 'created_at' }
    before { Course.create! organization: 'example.org', name: 'foo', slug: 'example.org/foo' }
    before { Student.create!(student.merge(uid: 'auth0|1', organization: 'example.org', course: 'example.org/foo')) }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/student/auth0%7c1' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_like student.merge({organization: 'example.org', course: 'example.org/foo', uid: 'auth0|1'}), except_fields }
  end

  describe 'post /courses/:course/students/:student_id' do

    before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', uid: 'github|123456', tenant: 'example.org') }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/students/github%7C123456' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_eq status: :created }
  end

  describe 'put /courses/:course/students/:student_id' do

    before { User.create! first_name: 'Jon', last_name: 'Din', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', permissions: {student: 'example.org/*'} }
    before { Student.create! first_name: 'Jon', last_name: 'Din', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo', organization: 'example.org', course: 'example.org/foo' }
    before { Course.create! organization: 'example.org', name: 'foo', slug: 'example.org/foo' }
    before { header 'Authorization', build_auth_header('*') }
    before { put '/courses/foo/students/jondoe@gmail.com', {last_name: 'Doe'}.to_json }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_eq status: :updated }
    it { expect(Student.find_by(uid: 'jondoe@gmail.com').last_name).to eq 'Doe' }
  end

  describe 'when needs mumuki-user' do
    let(:fetched_student) { Student.find_by(uid: 'github|123456') }


    describe 'post /courses/:course/students/:student_id/detach' do

      before { create_student!.call student1 }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example.org/*') }
        before { post '/courses/example/students/github%7C123456/detach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_eq status: :updated }
        it { expect(fetched_student.detached).to eq true }
      end

    end

    describe 'post /courses/:course/students/:student_id/attach' do

      before { create_student!.call student1.merge(detached: true, detached_at: Time.now) }

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
      let(:from_student) { -> (student) { student.map {|k, v| ["student.#{k}", v] }.to_h } }

      let(:guide1) { {slug: 'example.org/bar'} }
      let(:guide2) { {slug: 'some_orga/baz'} }
      before { create_student!.call student1 }
      before { create_assignment!.call exercise1 }
      before { create_student_guide_progress!.call guide_student_progress1 }
      before { create_student_guide_progress!.call guide_student_progress2 }

      let(:fetched_guide_progresses) { GuideProgress.where(from_student.call(student1)).to_a }
      let(:fetched_assignments) { Assignment.where(from_student.call(student1)).to_a }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('*/*') }
        before { post '/courses/example/students/github%7C123456/transfer', { slug: 'some_orga/some_course' }.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.organization).to eq 'some_orga' }
        it { expect(fetched_student.course).to eq 'some_course' }

        it { expect(fetched_guide_progresses.count).to eq 2 }
        it { expect(fetched_guide_progresses.first.matches? organization: 'example.org', course: 'example.org/example').to eq true }
        it { expect(fetched_guide_progresses.last.matches? organization: 'some_orga', course: 'some_course').to eq true }
        it { expect(fetched_assignments.all? { |it| it.matches? organization: 'some_orga', course: 'some_course'}).to eq true }
      end

    end

    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        before { Course.create! organization: 'example.org', name: 'foo', slug: 'example.org/foo' }
        before { Course.create! organization: 'example.org', name: 'bar', slug: 'example.org/bar' }

        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Student.count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish in resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
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
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
            context 'in different course, should works' do
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

          post '/courses/foo/students', student_json

          expect(last_response).to_not be_ok
          expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 0
        end
      end
    end

    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo', personal_id: '1234'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        before { Course.create! organization: 'example.org', name: 'foo', slug: 'example.org/foo' }

        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish int resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example.org', course: 'example.org/foo'), except_fields) }
            end
            context 'and user does not exist' do
              let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo'} }
              let(:created_course_student) { Student.find_by(organization: 'example.org', course: 'example.org/foo').as_json }
              let(:created_at) { 'created_at' }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example.org', course: 'example.org/foo'), except_fields) }
            end
          end
          context 'should not publish int resubmissions queue' do
            before { post '/courses/foo/students', student_json }
            before { expect(Mumukit::Nuntius).to_not receive(:notify!) }
            context 'and user already exists by uid' do
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
            context 'and user already exists by email' do
              before { header 'Authorization', build_auth_header('*', 'auth1') }
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
          end
        end

      end

      context 'when course does not exist' do
        before { expect(Mumukit::Nuntius).to_not receive(:notify!) }

        it 'rejects creating a student' do
          header 'Authorization', build_auth_header('*')

          post '/courses/foo/students', student_json

          expect(last_response).to_not be_ok
          expect(Student.where(organization: 'example.org', course: 'example.org/foo').count).to eq 0
        end
      end
    end
  end

  describe 'students routes with params' do

    describe 'get /courses/:course/students' do

      let(:except_fields) { {except: [:created_at, :updated_at]} }

      let(:student1) { {uid: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', organization: 'example.org', course: 'example.org/foo'} }
      let(:student2) { {uid: 'jondoe@gmail.com', first_name: 'jon', last_name: 'doe', organization: 'example.org', course: 'example.org/foo'} }
      let(:student3) { {uid: 'walter@gmail.com', first_name: 'wal', last_name: 'ter', organization: 'example.org', course: 'example.org/foo'} }
      let(:student4) { {uid: 'zzztop@gmail.com', first_name: 'zzz', last_name: 'top', organization: 'example.org', course: 'example.org/foo', detached: true} }

      before { Student.create! student1 }
      before { Student.create! student2 }
      before { Student.create! student3 }
      before { Student.create! student4 }

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


end
