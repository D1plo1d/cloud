#!/bin/sh

# install and configure the server
/vagrant/script/install.sh

cd /vagrant

# migrating the database and creating it if it does not already exist
rake db:create
rake db:migrate

# Starting the various server components as daemons using bluepill
sudo bluepill load ./config/blue_pill.rb
