#!/bin/bash

if [ ! -f bounces.db  ]; then
    echo "creating bounces.db"
    sqlite3 bounces.db < db/schema.sqlite3
fi

if [ ! -d eml ]; then
    echo "Please put all mails into eml/ if you want to use this script!"
else
    echo "clean eml filenames"
    for f in eml/*\ *; do mv "$f" "${f// /_}"; done
    echo "process mails"
    for f in eml/*; do ./email-processor/bounce-processor.pl < $f; done

    echo "extract list with non-spam bounces"
    query="select user, name from mailing_blacklist u, mailing_domains d where u.reason<>'spam' and u.reason<>'unknown' and u.domain_id = d.id;"
    sqlite3 bounces.db "$query" | sort | uniq | awk '{ sub(/\|/, "@"); print }'
fi

