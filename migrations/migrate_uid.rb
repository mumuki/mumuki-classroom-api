def do_migrate!
  Classroom::Database.within_each do
    Classroom::Collection::CourseStudents.all.each do |course_student|
      course = course_student.course['slug'].split('/').last
      social_id = course_student.student['social_id']
      uid = course_student.student['email'] || social_id
      Classroom::Collection::Students.for(course).update_one({social_id: social_id}, { '$set': {uid: uid}})
      Classroom::Collection::CourseStudents.update_many({'student.social_id': social_id}, { '$set': {'student.uid': uid}})
      Classroom::Collection::GuideStudentsProgress.for(course).update_many({'student.social_id': social_id}, { '$set': {'student.uid': uid}})
      Classroom::Collection::ExerciseStudentProgress.for(course).update_many({'student.social_id': social_id}, { '$set': {'student.uid': uid}})
    end
    Classroom::Collection::Courses.all.each do |course|
      course = course.slug.split('/').last
      Classroom::Collection::Teachers.for(course).all.each do |teacher|
        social_id = teacher.social_id
        uid = teacher.email || social_id
        Classroom::Collection::Teachers.for(course).update_one({social_id: social_id}, { '$set': {uid: uid} })
      end
      Classroom::Collection::Followers.for(course).all.each do |follower|
        uids = follower.social_ids&.map do |social_id|
          Classroom::Collection::Students.for(course).find_by({social_id: social_id})&.uid
        end&.compact || []
        Classroom::Collection::Followers.for(course).update_one({email: follower.email}, { '$set': {uids: uids, uid: follower.email} })
      end
      Classroom::Collection::Exams.for(course).all.each do |exam|
        uids = exam.social_ids&.map do |social_id|
          Classroom::Collection::Students.for(course).find_by({social_id: social_id})&.uid
        end&.compact || []
        Classroom::Collection::Exams.for(course).update_one(exam.as_json, { '$set': {uids: uids} })
      end
    end
    Classroom::Collection::FailedSubmissions.all.each do |submission|
      Classroom::Collection::FailedSubmissions.update_one(submission.as_json, { '$set': { uid: (submission.submitter[:email] || submission.submitter[:social_id])} })
    end
  end
end
