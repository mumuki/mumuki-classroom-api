# Mumuki::Classroom
Short description and motivation.

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
apt-get install mongodb-org -y
```

And then `reboot` your machine.  

#### 2. Install ruby essentials 

```bash
sudo apt-get install autoconf curl git build-essential libssl-dev autoconf bison libreadline6 libreadline6-dev zlib1g zlib1g-dev rabbitmq-server
```ruby
```

And then execute:
```bash
$ bundle
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
