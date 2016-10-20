[![Build Status](https://travis-ci.org/mumuki/mumuki-classroom-api.svg?branch=master)](https://travis-ci.org/mumuki/mumuki-classroom-api)

# Mumuki Classroom (API)
> Tools for tracking students' progress within Mumuki

## Installing the server

```
bundle install
```

## Running the server

```
bundle exec rackup
```

## Running tasks

### Queues processing

```bash
# starts commands consumer
bundle exec rake commands:listen

# starts submissions consumer
bundle exec rake submissions:listen

# starts resubmissions consumer
bundle exec rake resubmissions:listen
```

### Reports

```bash
# registered and active users reports
bundle exec rake students:reports:registered[<organization>,<course>,<from>,<to>,<json|table|csv>]
bundle exec rake students:reports:active[<organization>,<course>,<from>,<to>,<json|table|csv>]
```

### Migrations

```bash
# migration_name is the name of the migration file in ./migrations/, without extension and the "migrate_" prefeix
bundle exec rake db:migrate[<migration_name>]
