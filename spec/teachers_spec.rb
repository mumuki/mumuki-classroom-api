require 'spec_helper'

describe Teacher do

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  describe 'get /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Teacher.create! teacher.merge(organization: 'example.org', course: 'example.org/foo') }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({teachers: [teacher.merge(organization: 'example.org', course: 'example.org/foo')]}, except_fields) }
    end

  end

  describe 'post /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar'} }

    context 'when success' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to be_ok }
      it { expect(Teacher.count).to eq 1 }
      it { expect(Teacher.first.as_json).to json_like(teacher.merge(first_name: 'Foo', last_name: 'Bar', organization: 'example.org', course: 'example.org/foo', uid: 'foobar@gmail.com'), except_fields) }
    end

    context 'when no permissions' do
      before { header 'Authorization', build_auth_header('') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Teacher.count).to eq 0 }
    end

  end

  describe 'post api/courses/massive/:course/teachers' do
    let(:teachers) do
      (1.. 120).map do |it|
        {first_name: "first_name_#{it}", last_name: "last_name_#{it}", email: "email_#{it}@fake.com"}
      end
    end
    let(:teachers_uids) { teachers.map { |it| it[:email] } }
    let(:teachers_json) { {teachers: teachers}.to_json }

    context 'when course exists' do
      before { Course.create! organization: 'example.org', name: 'foo', slug: 'example.org/foo' }

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }

        context 'and users do not exist' do
          before { expect(Mumukit::Nuntius).to receive(:notify!).exactly(100).times }
          before { post 'api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_eq({status: 'created', processed_count: 100},
                                                     {only: [:status, :processed_count]}) }
          it { expect(Teacher.in(uid: teachers_uids).where(course: 'example.org/foo').count).to eq 100 }
        end

        context 'and some users do exist' do
          before do
            teachers_uids.take(50).map do |it|
              user = User.create(uid: it)
              user.add_permission! :teacher, 'example.org/foo2'
              user.save!
              Teacher.create(organization: 'example.org', course: 'example.org/foo2', uid: it)
            end
          end
          before { expect(Mumukit::Nuntius).to receive(:notify!).exactly(100).times }
          before { post 'api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({status: 'created', processed_count: 100}, only: [:status, :processed_count]) }
          it { expect(Teacher.in(uid: teachers_uids).where(organization: 'example.org', course: 'example.org/foo').count).to eq 100 }
          it { expect(User.in(uid: teachers_uids).count).to eq 100 }
          it { expect(User.in(uid: teachers_uids).select { |it| it.teacher_of? struct(slug: 'example.org/foo') }.count).to eq 100 }
          it { expect(User.in(uid: teachers_uids).select { |it| it.teacher_of? struct(slug: 'example.org/foo2') }.count).to eq 50 }
        end

        context 'and some teachers do exist' do
          before { Teacher.create(organization: 'example.org', course: 'example.org/foo', uid: teachers[99][:email]) }
          before { post 'api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({existing_members: [teachers[99]]},
                                                       {only: [:existing_members]}) }
          it { expect(Teacher.in(uid: teachers_uids).count).to eq 100 }
        end
      end

    end

  end

end
