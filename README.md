[![Build Status](https://travis-ci.org/mumuki/mumuki-classroom-api.svg?branch=master)](https://travis-ci.org/mumuki/mumuki-classroom-api)
[![Code Climate](https://codeclimate.com/github/mumuki/mumuki-classroom-api/badges/gpa.svg)](https://codeclimate.com/github/mumuki/mumuki-classroom-api)
[![Test Coverage](https://codeclimate.com/github/mumuki/mumuki-classroom-api/badges/coverage.svg)](https://codeclimate.com/github/mumuki/mumuki-classroom-api)
[![Issue Count](https://codeclimate.com/github/mumuki/mumuki-classroom-api/badges/issue_count.svg)](https://codeclimate.com/github/mumuki/mumuki-classroom-api)



# Mumuki Classroom (API)
> Tools for tracking students' progress within Mumuki

## Preparing environment

### 1. Install essentials and base libraries

> First, we need to install some software: MongoDB and some common Ruby on Rails native dependencies

#### 1. Install Mongo 3.4

[This process depends on you OS](https://docs.mongodb.com/v3.4/installation/). On ubuntu, follow these instructions: 

```sh
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6  &&
echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list &&
sudo apt-get update &&
apt-get remove --purge mongo* -y &&
apt-get autoremove -y &&
apt-get install mongodb-org -y &&
```

And then `reboot` your machine.  

#### 2. Install ruby essentials 

```bash
sudo apt-get install autoconf curl git build-essential libssl-dev autoconf bison libreadline6 libreadline6-dev zlib1g zlib1g-dev
```

### 2. Install rbenv

> [rbenv](https://github.com/rbenv/rbenv) is a ruby versions manager, similar to rvm, nvm, and so on.

```bash
curl https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc # or .bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bashrc # or .bash_profile
```

### 3. Install ruby

> Now we have rbenv installed, we can install ruby and [bundler](http://bundler.io/)

```bash
rbenv install 2.3.1
rbenv global 2.3.1
rbenv rehash
gem install bundler
gem install escualo
```

### 4. Clone this repository

> Because, err... we need to clone this repostory before developing it :stuck_out_tongue:

```bash
git clone https://github.com/mumuki/mumuki-classroom-api classroom-api
cd classroom-api
```

## Installing and Running

### Quick start

If you want to start the server quickly in developer environment,
you can just do the following:

```bash
./devstart
```

This will install your dependencies and boot the server.

### Installing the server

If you just want to install dependencies, just do:

```
bundle install
```

### Running the server

You can boot the server by using the standard rackup command:

```
# using defaults from config/puma.rb and rackup default port 9292
bundle exec rackup

# changing port
bundle exec rackup -p 8080

# changing threads count
MUMUKI_CLASSROOM_API_THREADS=30 bundle exec rackup
```

Or you can also start it with `puma` command, which gives you more control:

```
# using defaults from config/puma.rb
bundle exec puma

# changing ports and threads count, using puma-specific options:
bundle exec puma -t 2:30 -p 8080

# changing ports and threads count, using environment variables:
MUMUKI_CLASSROOM_API_PORT=8080 MUMUKI_CLASSROOM_API_THREADS=30 bundle exec puma
```

## Running tests

```bash
bundle exec rspec
```

## Running tasks

```bash
# starts commands consumer
bundle exec rake commands:listen

# starts submissions consumer
bundle exec rake submissions:listen

# starts resubmissions consumer
bundle exec rake resubmissions:listen
```

## Running Reports

```bash
# registered and active users reports
bundle exec rake students:reports:registered[<organization>,<course>,<from>,<to>,<json|table|csv>]
bundle exec rake students:reports:active[<organization>,<course>,<from>,<to>,<json|table|csv>]
```

## Running Migrations

```bash
# migration_name is the name of the migration file in ./migrations/, without extension and the "migrate_" prefix
bundle exec rake db:migrate[<migration_name>]
```

## Api


### Add student to exam

**Minimal permission**: `janitor`

```
POST /api/courses/:course/exams/:exam_id/students/:uid
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

### Courses


**Minimal permission**: `teacher`

```
GET /api/courses/
```

**Response**
```json
{
    "courses": [
        {
            "uid": "staging-digitalhouse/2017-1",
            "days": [
                "Lunes"
            ],
            "code": "1",
            "shifts": [
                "Mañana"
            ],
            "period": "2017",
            "description": "Curso de prueba",
            "slug": "staging-digitalhouse/2017-1"
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

### Students

**Minimal permission**: `teacher`

```
GET /api/courses/:course/students
```
```json

{
  "students": [
      {
          "name": "johndoe",
          "email": "johndoe@gmail.com",
          "image_url": "https://s.gravatar.com/avatar/ca995a4f4ba1aafbd71a6403aa78635c?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fsa.png",
          "social_id": "auth0|57e035e9e6379dd660dbcd",
          "first_name": "John",
          "last_name": "Doe",
          "last_assignment": null,
          "uid": "johndoe@gmail.com",
          "created_at": "2016-09-19T19:01:11.000Z"
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
