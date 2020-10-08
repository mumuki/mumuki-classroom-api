class Mumuki::Classroom::Event::ProgressTransfer::Copy < Mumuki::Classroom::Event::ProgressTransfer::Base
  def transfer_sibling_for(assignment)
    classroom_sibling_for(assignment).dup
  end

  def transfer_item
    guide_progress.dup
  end
end
