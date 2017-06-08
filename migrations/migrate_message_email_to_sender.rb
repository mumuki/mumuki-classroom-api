def do_migrate!
  puts "Migrating messages..."
  total = Assignment.count
  Assignment.all.each_with_index do |assignment, index|
    puts "Migrating #{index + 1} of #{total}"
    assignment.submissions.each do |submission|
      next unless submission.comments.present?
      submission.set(messages: submission.comments)
      submission.unset(:comments)
      submission.messages.each do |message|
        message.set(sender: message.email)
        message.set(created_at: Time.parse(message.date))
        message.unset(:email)
        message.unset(:date)
      end
      assignment.upsert_attributes(submissions: assignment.submissions)
    end
  end
  puts "Done!"
end
