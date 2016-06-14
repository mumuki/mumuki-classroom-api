require 'spec_helper'

describe Classroom::Submission do

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
      let(:guide_students_progress) { Classroom::Collection::GuideStudentsProgress.for('example').all.as_json.deep_symbolize_keys[:guide_students_progress] }
      let(:exercise_student_progress) { Classroom::Collection::ExerciseStudentProgress.for('example').all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { Classroom::Collection::Guides.for('example').insert! guide1.wrap_json }
      before { Classroom::Collection::Guides.for('example').insert! guide2.wrap_json }

      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress1.wrap_json }
      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress2.wrap_json }
      before { Classroom::Collection::GuideStudentsProgress.for('example').insert! guide_student_progress3.wrap_json }

      before { Classroom::Collection::Students.for('example').delete_cascade!('github|123456', 'example/example') }

      it { expect(guides.size).to eq 1 }
      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(exercise_student_progress.size).to eq 1 }

    end

  end

end
