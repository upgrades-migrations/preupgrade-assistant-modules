#!/bin/bash
echo "#prevent replace during in-place upgrade - lines below are generated" >>/etc/login.defs
echo "SYS_UID_MIN               201" >>/etc/login.defs
echo "SYS_UID_MAX               499" >>/etc/login.defs
