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
```

## Api


### Add student to exam

**Minimal permission**: `janitor`

```
POST /api/courses/:course/exam/:exam_id/students/:uid
```

**Response**
```json
{
    "status": "updated",
    "id": "9d0045448aae977a"
}
```
**Forbidden Response**
```json
{
  "status": 403,
  "error": "Exception"
}
```

### Guides


**Minimal permission**: `teacher`

```
GET /api/courses/:course/guides
```

**Response**
```json
{
  "guides": [
      {
          "slug": "sagrado-corazon-alcal/mumuki-guia-fundamentos-primeros-programas",
          "name": "Primeros Programas",
          "parent": {
              "type": "Lesson",
              "name": "Primeros Programas",
              "position": 1,
              "chapter": {
                  "id": 13,
                  "name": "Fundamentos"
              }
          },
          "language": {
              "name": "gobstones"
          },
          "lesson": {
              "id": 13,
              "name": "Fundamentos"
          }
      }
   ]
}
```
**Forbidden Response**
```json
{
  "status": 403,
  "error": "Exception"
}
```

### Students progress

**Minimal permission**: `teacher`

```
GET /api/courses/:course/students/:uid
```
```json

{
    "guide_students_progress": [
        {
            "guide": {
                "slug": "sagrado-corazon-alcal/mumuki-guia-fundamentos-primeros-programas",
                "name": "Primeros Programas",
                "parent": {
                    "type": "Lesson",
                    "name": "Primeros Programas",
                    "position": 1,
                    "chapter": {
                        "id": 13,
                        "name": "Fundamentos"
                    }
                },
                "language": {
                    "name": "gobstones"
                }
            },
            "student": {
                "uid": "john.doe@gmail.com",
                "email": "john.doe@gmail.com",
                "last_name": "Doe",
                "first_name": "John"
            },
            "stats": {
                "passed": 13,
                "failed": 0,
                "passed_with_warnings": 0
            },
            "last_assignment": {
                "exercise": {
                    "id": 290,
                    "name": "Sacar Bolitas",
                    "number": 11
                },
                "submission": {
                    "id": "12345667890abcdg",
                    "status": "passed",
                    "result": "",
                    "content": "program {\r\n  Mover(Sur)\r\n  Sacar(Rojo)\r\n}",
                    "feedback": "",
                    "created_at": "2017-01-06T00:43:48.176Z",
                    "test_results": [
                        {
                            "title": null,
                            "status": "passed",
                            "result": "foo"
                        }
                    ],
                    "submissions_count": 2,
                    "expectation_results": [
                        {
                            "binding": "program",
                            "inspection": "HasBinding",
                            "result": "passed"
                        }
                    ]
                }
            }
        }
    ]
}
``` 

**Forbidden Response**
```json
{
  "status": 403,
  "error": "Exception"
}
```
