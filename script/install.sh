#!/bin/sh

# exit on error
set -o errexit

# echos commands being run
set -o xtrace

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Setting up the development environment
if ["$RAILS_ENV" -eq "development" || "$RAILS_ENV" -eq "" ]; then
  export RAILS_ENV="development"
fi

if ["$RAILS_ENV" -eq "development"]; then
  export RAILS_ROOT="${DIR}/.."
else
  export RAILS_ROOT="${DIR}"
fi

#sudo apt-get update -y -qq # only needs to be run on the initial vm creation
sudo apt-get install -y -q git curl

# Ruby 1.9
sudo apt-get install -y -q ruby1.9.1 ruby1.9.1-dev \
  rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
  build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev

# Needed for nokigiri
sudo apt-get install -y -q libxml2 libxml2-dev libxslt1-dev

# Needed for rmagick
sudo apt-get install -y -q imagemagick libmagickcore-dev libmagickwand-dev # graphicsmagick-libmagick-dev-compat

# Needed for resque
sudo apt-get install -y -q redis-server

# Needed for Meshlab - TODO: This may be an old version, and if so, we should shift to 1.30a
#sudo apt-get install -y xvfb
#sudo apt-get install -y meshlab
#sudo apt-get install -y libicu-dev
#sudo apt-get install -y qt4-make

# OpenSCAD
#udo apt-get install -y python-software-properties
#sudo add-apt-repository -y ppa:chrysn/openscad
#sudo apt-get update
#sudo apt-get install -y openscad

# Slic3r
sudo apt-get install -y xvfb x11-xkb-utils xserver-xorg-core # Headless X Display

sudo apt-get install -y git build-essential libgtk2.0-dev libwxgtk2.8-dev libwx-perl libmodule-build-perl libnet-dbus-perl cpanminus libwx-perl

sudo xvfb-run cpanm Boost::Geometry::Utils Math::Clipper \
    Math::ConvexHull Math::Geometry::Voronoi Math::PlanePath Moo Wx


if [[ `which mysql` ]]; then
    echo 'mysql already installed'
else
    # install mysql, seeding root mysql password
    MYSQL_PASSWORD=development

    cat <<MYSQL_PRESEED | sudo debconf-set-selections
mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD
mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD
mysql-server-5.5 mysql-server/start_on_boot boolean true
MYSQL_PRESEED

    sudo apt-get install -y -q mysql-server mysql-client libmysql-ruby1.9.1 libmysqlclient-dev

    echo "GRANT ALL PRIVILEGES ON *.* TO 'gitforge'@'localhost' IDENTIFIED BY 'gitforge\!' WITH GRANT OPTION;" | mysql -uroot -p$MYSQL_PASSWORD
fi

# Setting up BluePill for server management
if [[ `which bluepill` ]]; then
    echo 'bluepill already installed'
else
  sudo gem install bluepill

  sudo touch /etc/syslog.conf
  sudo chmod 777 /etc/syslog.conf
  sudo echo "local6.*          /var/log/bluepill.log" >> /etc/syslog.conf
  sudo chmod 644 /etc/syslog.conf

  sudo mkdir -p /var/run/bluepill

  sudo touch /var/log/bluepill.log
  sudo chmod 777 /var/log/bluepill.log
fi

# Finally install bundler if it isn't already
which bundle || sudo gem install bundler --no-rdoc --no-ri

# and update our bundled gems
bundle install

if ["$RAILS_ENV" -eq "development"]; then
# setting up base sessions so they start in the /vagrant share by default
echo "cd /vagrant" >> /home/vagrant/.bashrc
fi


# Adding a Slic3r User
# TODO: At some point in the future someone with super cow powers should chown 
# jail this user because the slic3r code is not to be trusted.
if id -u sliceruser >/dev/null 2>&1; then
  echo "slic3ruser and slicerusers already set up"
else
  # Adding the sliceruser to the slicerusers group
  sudo groupadd slicerusers
  sudo useradd -m -g slicerusers sliceruser

  # Adding the rails user to the slicerusers group
  sudo usermod -a -G slicerusers `whoami`

  # TODO
  #sudo echo "`whoami` ALL=NOPASSWD: /bin/su - sliceruser" > /etc/sudoers
  echo ""
  echo "-----------------------------------------------------"
  echo " IMPORTANT: YOU MUST EDIT THE SUDOER FILE MANUALLY"
  echo "-----------------------------------------------------"
  echo "using visudo:"
  echo "  `whoami` ALL=NOPASSWD: /vagrant/script/slicer.sh"
  echo "-----------------------------------------------------"
  echo ""
fi


# Setting up Slic3r
if [ -d /home/sliceruser/slic3r ]; then
  echo 'slic3r already installed'
else
  cd /home/sliceruser/
  sudo mkdir -p slic3r
  sudo chown sliceruser:slicerusers slic3r
  sudo chmod 777 slic3r

  sudo mkdir -p slic3r_jobs/g_codes
  sudo chown sliceruser:slicerusers slic3r_jobs
  # TODO: carrierwave can't upload to this folder with 775, not sure why.
  sudo chmod 777 slic3r_jobs
  sudo chmod 777 slic3r_jobs/g_codes

  cd slic3r
  git init
  git remote add origin git://github.com/alexrj/Slic3r.git
  git pull origin master
fi

sudo cp "${RAILS_ROOT}/config/cube.stl" /home/sliceruser/cube.stl
sudo chown sliceruser:slicerusers /home/sliceruser/cube.stl

