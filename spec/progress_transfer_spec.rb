require 'spec_helper'

describe Mumuki::Classroom::Event::ProgressTransfer do
  let(:user) { create(:user, permissions: { student: 'source_organization/*:destination_organization/*' }) }

  let(:source_organization) { create(:organization, name: 'source_organization', book: book) }
  let(:destination_organization) { create(:organization, name: 'destination_organization', book: book) }
  let(:book) { create(:book, chapters: [create(:chapter, topic: topic)]) }
  let(:topic) { create(:topic, lessons: [create(:lesson, guide: guide)]) }
  let(:guide) { create(:guide, exercises: [exercise_1, exercise_2]) }
  let(:exercise_1) { create(:exercise) }
  let(:exercise_2) { create(:exercise) }

  let(:guide_indicator) { guide.progress_for(user, source_organization) }

  let!(:source_student) { create(:student, organization: source_organization.name, uid: user.uid) }
  let!(:destination_student) { create(:student, organization: destination_organization.name, uid: user.uid) }

  before { stub_runner! status: :failed  }

  def submit_solution!(exercise, user, content, status)
    assignment = exercise.submit_solution!(user, { content: content }).tap { |it| it.update! status: status }
    Mumuki::Classroom::Submission.process! assignment.to_resource_h
  end

  def move_to!(indicator, organization)
    indicator.move_to!(organization)
    execute_classroom_transfer_for!(indicator)
  end

  def copy_to!(indicator, organization)
    copy = indicator.copy_to!(organization)
    execute_classroom_transfer_for!(copy)
  end

  def execute_classroom_transfer_for!(indicator)
    Mumuki::Classroom::Event::ProgressTransfer.new(event.merge(item_id: indicator.id)).execute!
  end

  def event_for(source_organization, transfer_type)
    { from: source_organization.name, to: destination_organization.name, transfer_type: transfer_type }
  end

  before do
    source_organization.switch!
    submit_solution!(exercise_1, user, 'foo', :passed)
    destination_organization.switch!
    submit_solution!(exercise_2, user, 'bar', :failed)
  end

  context '#execute!' do
    context 'before transfer' do
      it { expect(Mumuki::Classroom::GuideProgress.count).to eq 2 }
      it { expect(source_student.reload.stats).to eq({ 'passed' => 1, 'failed' => 0, 'passed_with_warnings' => 0 }) }
      it { expect(destination_student.reload.stats).to eq({ 'passed' => 0, 'failed' => 1, 'passed_with_warnings' => 0 }) }
    end

    context 'on progress move' do
      let(:event) { event_for source_organization, 'move' }

      before { move_to!(guide_indicator, destination_organization) }

      it { expect(Mumuki::Classroom::GuideProgress.count).to eq 1 }
      it { expect(source_student.reload.stats).to eq({ 'passed' => 0, 'failed' => 0, 'passed_with_warnings' => 0 }) }
      it { expect(destination_student.reload.stats).to eq({ 'passed' => 1, 'failed' => 0, 'passed_with_warnings' => 0 }) }
    end

    context 'on progress copy' do
      let(:event) { event_for source_organization, 'copy' }

      before { copy_to!(guide_indicator, destination_organization) }

      it { expect(Mumuki::Classroom::GuideProgress.count).to eq 2 }
      it { expect(source_student.reload.stats).to eq({ 'passed' => 1, 'failed' => 0, 'passed_with_warnings' => 0 }) }
      it { expect(destination_student.reload.stats).to eq({ 'passed' => 1, 'failed' => 0, 'passed_with_warnings' => 0 }) }
    end
  end
end
