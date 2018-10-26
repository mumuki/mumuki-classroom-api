def do_migrate!
  puts "Dropping index"
  Student.drop_index 'first_name_text_last_name_text_email_text'
end
