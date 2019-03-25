#!/bin/sh


DIRS='
/opt/ya-skill
'

for line in $(pgrep -f /opt/ya-skill)
do
  kill -9 $line
#  rm $line
done


for run_dir in ${DIRS}
do
  pgrep -f "${run_dir}" > /dev/null || uwsgi -b 32768 --plugins psgi --socket 127.0.0.1:87 --psgi /opt/ya-skill/hook.pl --processes 2 --master --chdir /opt/ya-skill --daemonize /var/log/uwsgi/perl-skill.log --pidfile /var/run/uwsgi/perl-skill.pid
done







