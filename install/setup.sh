#!/bin/bash -ex
# ------------------------------------------------------------------------
# ==================================================================
# Copy/Start Services
# ==================================================================
cp /opt/slackObserver/install/slack-observer /etc/init.d/

chmod +x /etc/init.d/slack-observer

update-rc.d slack-observer defaults
# ------------------------------------------------------------------------
