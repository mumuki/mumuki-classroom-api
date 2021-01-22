class Mumuki::Classroom::Event::ProgressTransfer::Move < Mumuki::Classroom::Event::ProgressTransfer::Base
  def transfer_sibling_for(assignment)
    classroom_sibling_for(assignment)
  end

  def transfer_item
    guide_progress
  end
end
