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

```
# starts commands consumer
bundle exec rake commands:listen

# starts submissions consumer
bundle exec rake submissions:listen

# starts resubmissions consumer
bundle exec rake resubmissions:listen
```

### Reports

```
# registered and active users reports
bundle exec rake students:reports:registered[<organization>,<course>,<from>,<to>,<json|table|csv>]
bundle exec rake students:reports:active[<organization>,<course>,<from>,<to>,<json|table|csv>]
```
