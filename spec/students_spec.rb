require 'spec_helper'

describe Classroom::Collection::Students do

  after do
    Classroom::Database.clean!
  end

  describe do
    let(:created_at) { 'created_at' }
    let(:date) { Time.now }

    let(:student1) {{ social_id: 'github|123456' }}
    let(:student2) {{ social_id: 'github|234567' }}

    let(:guide1) {{ slug: 'foo/bar' }}
    let(:guide2) {{ slug: 'bar/baz' }}

    let(:guide_student_progress1) {{ guide: guide1, student: student1 }}
    let(:guide_student_progress2) {{ guide: guide2, student: student1 }}
    let(:guide_student_progress3) {{ guide: guide2, student: student2 }}

    let(:exercise1) {{
      guide: guide1,
      student: student1,
      exercise: { id: 1 },
      submissions: [
        { status: 'failed', created_at: date },
        { status: 'passed', created_at: date + 2.minutes },
        { status: 'failed', created_at: date + 1.minute }
      ]
    }}
    let(:exercise2) {{
      guide: guide1,
      student: student1,
      exercise: { id: 2 },
      submissions: [
        { status: 'failed', created_at: date },
        { status: 'passed', created_at: date + 1.minute },
        { status: 'failed', created_at: date + 2.minutes }
      ]
    }}
    let(:exercise3) {{
      guide: guide2,
      student: student1,
      exercise: { id: 3 },
      submissions: [
        { status: 'passed', created_at: date}
      ]
    }}
    let(:exercise4) {{
      guide: guide2,
      student: student2,
      exercise: { id: 4 },
      submissions: [
        { status: 'failed', created_at: date },
        { status: 'passed_with_warnings', created_at: date + 2.minutes }
      ]
    }}

    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { Classroom::Collection::Students.for('example').insert! student1.wrap_json }
    before { Classroom::Collection::Students.for('example').insert! student2.wrap_json }

    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise1.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise2.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise3.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise4.wrap_json }

    context 'if no students stats processed' do
      let(:students) { Classroom::Collection::Students.for('example').all.as_json.deep_symbolize_keys[:students] }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1.merge(created_at: created_at) }
      it { expect(students.second).to eq student2.merge(created_at: created_at) }
    end

    context 'if students stats processed' do
      let(:students) { Classroom::Collection::Students.for('example').all.as_json.deep_symbolize_keys[:students] }

      before { Classroom::Collection::Students.for('example').update_all_stats }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1.merge(created_at: created_at, stats: { passed: 2, passed_with_warnings: 0, failed: 1 }) }
      it { expect(students.second).to eq student2.merge(created_at: created_at, stats: { passed: 0, passed_with_warnings: 1, failed: 0 }) }
    end

    context 'delete student from students' do

      let(:guides) { Classroom::Collection::Guides.for('example').all.as_json.deep_symbolize_keys[:guides] }
      let(:students) { Classroom::Collection::Students.for('example').all.as_json.deep_symbolize_keys[:students] }
      let(:course_students) { Classroom::Collection::CourseStudents.all.as_json.deep_symbolize_keys[:array] }
      let(:guide_students_progress) { Classroom::Collection::GuideStudentsProgress.for('example').all.as_json.deep_symbolize_keys[:guide_students_progress] }
      let(:exercise_student_progress) { Classroom::Collection::ExerciseStudentProgress.for('example').all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { Classroom::Collection::Guides.for('example').insert! guide1.wrap_json }
      before { Classroom::Collection::Guides.for('example').insert! guide2.wrap_json }

      before { Classroom::Collection::CourseStudents.insert!({ student: student1, course: { slug: 'example/example' }}.wrap_json) }
      before { Classroom::Collection::CourseStudents.insert!({ student: student2, course: { slug: 'example/example' }}.wrap_json) }
      before { Classroom::Collection::CourseStudents.insert!({ student: student1, course: { slug: 'example/foo' }}.wrap_json) }

      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress1.wrap_json }
      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress2.wrap_json }
      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress3.wrap_json }

      before { Classroom::Collection::Students.for('example').delete!('github|123456') }

      it { expect(course_students.size).to eq 2 }
      it { expect(guides.size).to eq 1 }
      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(exercise_student_progress.size).to eq 1 }

    end

  end

  describe 'students routes' do

    describe 'get /courses/:course/students' do

      let(:created_at) { 'created_at' }
      before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
      let(:student) {{ email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar' }}

      let(:student1) {{ student: student, course: { slug: 'example/foo' }, created_at: created_at }}
      let(:student2) {{ student: student, course: { slug: 'example/test' }, created_at: created_at  }}

      before { header 'Authorization', build_auth_header('*') }

      context 'when guides already exists in a course' do
        before { Classroom::Collection::Students.for('foo').insert!(student1.wrap_json) }
        before { Classroom::Collection::Students.for('test').insert!(student2.wrap_json) }
        before { get '/courses/foo/students' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_eq students: [student1] }
      end

    end
  end

  describe 'post /courses/:course/students' do
    let(:auth0) {double('auth0')}
    before { allow(Mumukit::Auth::User).to receive(:new).and_return(auth0) }
    before { allow(auth0).to receive(:update_permissions) }
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:student_json) { student.to_json }

    context 'when course exists' do
      before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }

      context 'when not authenticated' do
        before { post '/courses/foo/students', student_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Classroom::Collection::Students.for('foo').count).to eq 0 }
      end

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }

        context 'should publish int resubmissions queue' do
          before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_resubmissions) }
          before { post '/courses/foo/students', student_json }
          context 'and user does not exist' do
            let(:created_course_student) { Classroom::Collection::Students.for('foo').find_by({}).as_json }
            let(:created_at) { 'created_at' }
            before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }

            it { expect(last_response).to be_ok }
            it { expect(last_response.body).to json_eq status: 'created' }
            it { expect(Classroom::Collection::Students.for('foo').count).to eq 1 }
            it { expect(created_course_student.deep_symbolize_keys).to eq(student.merge(social_id: 'github|user123456', created_at: created_at)) }
          end
        end
        context 'should not publish int resubmissions queue' do
          before { expect(Mumukit::Nuntius::Publisher).to_not receive(:publish_resubmissions) }
          before { post '/courses/foo/students', student_json }
          context 'and user already exists by social_id' do
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
      before { expect(Mumukit::Nuntius::Publisher).to_not receive(:publish_resubmissions) }

      it 'rejects creating a student' do
        header 'Authorization', build_auth_header('*')

        post '/courses/foo/students', student_json

        expect(last_response).to_not be_ok
        expect(Classroom::Collection::Students.for('foo').count).to eq 0
      end
    end
  end

  describe 'put /courses/:course/students' do
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:student2) { {first_name: 'Agus', last_name: 'Pina', social_id: 'auth0|1' }}
    let(:json) {{ student: student.merge(social_id: 'auth0|1'), course: { slug: 'example/foo' }}}


    context 'when courses exists' do
      before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }

      context 'when not authenticated' do
        before { put '/courses/foo/student', student2}

        it { expect(last_response).to_not be_ok }
      end

      context 'when authenticated' do
        let(:created_at) { 'created_at' }
        before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
        before { Classroom::Collection::CourseStudents.insert! json.wrap_json }
        before { Classroom::Collection::Students.for('foo').insert!(student.merge(social_id: 'auth0|1').wrap_json) }
        before { header 'Authorization', build_auth_header('*') }
        before { put '/courses/foo/student', student2.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_eq status: 'updated' }
        it { expect(Classroom::Collection::Students.for('foo').find_by('social_id' => 'auth0|1').raw[:first_name]).to eq 'Agus' }
        it { expect(Classroom::Collection::Students.for('foo').find_by('social_id' => 'auth0|1').raw[:last_name]).to eq 'Pina' }
        it { expect(Classroom::Collection::Students.for('foo').count).to eq 1 }
        it { expect(Classroom::Collection::CourseStudents.count).to eq 1 }
        it { expect(Classroom::Collection::CourseStudents.find_by('student.social_id' => 'auth0|1', 'course.slug' => 'example/foo').raw[:student][:first_name]).to eq 'Agus' }
        it { expect(Classroom::Collection::CourseStudents.find_by('student.social_id' => 'auth0|1', 'course.slug' => 'example/foo').raw[:student][:last_name]).to eq 'Pina' }
      end
    end

  end

  describe 'get /courses/:course/student/:social_id' do
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:json) {{ student: student.merge(social_id: 'auth0|1'), course: { slug: 'example/foo' }}}
    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }
    before { Classroom::Collection::CourseStudents.insert! json.wrap_json }
    before { Classroom::Collection::Students.for('foo').insert!(student.merge(social_id: 'auth0|1').wrap_json) }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/student/auth0%7c1' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_eq student.merge(created_at: created_at, social_id: 'auth0|1') }
  end


end
