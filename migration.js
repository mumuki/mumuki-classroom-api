
function col(course, prefix) {
  var underscoredCourse = course
    .split('')
    .map(function (c) { return c === '-' ? '_' : c })
    .join('');

  return db[prefix + '_' + underscoredCourse];
}

function guide_from(progress) {
  progress.guide.lesson = progress.guide.chapter;
  delete progress.guide.chapter;
  return progress.guide;
}

function guide_student_progress_from(progress) {
  return {
    guide: guide_from(progress),
    student: progress.student,
    stats: stats_from(progress.exercises),
    last_assignment: last_assignment_from(progress.exercises)
  }
}

function stats_from(exercises) {
  var stats = {
    passed: 0,
    failed: 0,
    passed_with_warnings: 0
  };
  exercises.forEach(function (exercise) {
    stats[last_submission(exercise.submissions).status]++;
  });
  return stats;
}

function exercise_from(exercise) {
  return {
    id: exercise.id,
    name: exercise.name,
    number: exercise.number
  };
}

function last_submission(submissions) {
  var last = null;
  submissions.forEach(function (submission) {
    if (!last || submission.created_at > last.created_at) {
      last = submission;
    }
  });
  return last;
}

function last_assignment_from(exercises) {
  var ret = {};

  exercises.forEach(function (exercise) {
    var lastSubmission = last_submission(exercise.submissions);

    if (!ret.submission || (lastSubmission.created_at > ret.submission.created_at )) {
      ret.exercise = exercise_from(exercise);
      ret.submission = lastSubmission;
    }
  });

  return ret;
}

function exercise_progress_from(progress, exercise) {
  return {
    guide: guide_from(progress),
    student: progress.student,
    submissions: exercise.submissions,
    exercise: exercise_from(exercise)
  }
}

db.guides_progress.find().forEach(function (progress) {

  db.course_students.update(
    { 'student.social_id': progress.student.social_id },
    { '$set': { 'student': progress.student } },
    { 'multi': true }
  );

  if (!progress && !progress.course && !progress.course.slug) return;

  var course = progress.course.slug.split('/')[1];

  col(course, 'students').update(
    { 'social_id': progress.student.social_id },
    { '$set': progress.student },
    { 'upsert': true }
  );

  col(course, 'guides').update(
    { 'slug': progress.guide.slug },
    { '$set': guide_from(progress) },
    { 'upsert': true }
  );

  col(course, 'guide_students_progress').update(
    { 'guide.slug': progress.guide.slug, 'student.social_id': progress.student.social_id },
    { '$set': guide_student_progress_from(progress) },
    { 'upsert': true }
  );

  progress.exercises.forEach(function (exercise) {
    col(course, 'exercise_student_progress').update(
      { 'guide.slug': progress.guide.slug, 'student.social_id': progress.student.social_id, 'exercises.id': exercise.id },
      { '$set': exercise_progress_from(progress, exercise) },
      { 'upsert': true }
    );
  });

});

db.followers.find().forEach(function (follower) {

  if (!follower && !follower.course) return;

  var course = follower.course.split('/')[1];

  col(course || '', 'followers').update(
    { 'course': follower.course, 'email': follower.email },
    { '$set': follower },
    { 'upsert': true, 'multi': true }
  );

});
