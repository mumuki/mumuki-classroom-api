require 'spec_helper'

describe Classroom::Submission do

  after do
    Classroom::Database.clean!
  end

  describe do
    let(:date) { Time.now }
    let(:student1) {{ social_id: 'github|123456' }}
    let(:student2) {{ social_id: 'github|234567' }}
    let(:guide1) {{ slug: 'foo/bar' }}
    let(:guide2) {{ slug: 'bar/baz' }}

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

    before { Classroom::Collection::Students.for('example').insert! student1.wrap_json }
    before { Classroom::Collection::Students.for('example').insert! student2.wrap_json }

    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise1.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise2.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise3.wrap_json }
    before { Classroom::Collection::ExerciseStudentProgress.for('example').insert! exercise4.wrap_json }

    context 'if no students stats processed' do
      let(:students) { Classroom::Collection::Students.for('example').all.as_json.deep_symbolize_keys[:students] }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1 }
      it { expect(students.second).to eq student2 }
    end

    context 'if students stats processed' do
      let(:students) { Classroom::Collection::Students.for('example').all.as_json.deep_symbolize_keys[:students] }

      before { Classroom::Collection::Students.for('example').update_all_stats }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1.merge(stats: { passed: 2, passed_with_warnings: 0, failed: 1 }) }
      it { expect(students.second).to eq student2.merge(stats: { passed: 0, passed_with_warnings: 1, failed: 0 }) }
    end


  end

end
