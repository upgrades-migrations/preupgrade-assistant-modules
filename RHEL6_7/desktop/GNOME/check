#! /usr/bin/env bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION

# We need to have Xorg installed to check for presence of any available gnome sessions

RESULT="$RESULT_PASS"
if test -f /usr/share/xsessions/gnome.desktop; then
    log_extreme_risk "You have the GNOME Desktop Environment session as an option in your X11 session manager. GNOME Desktop Environment as a part of the yum group 'Desktop' underwent a serious redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7."
    RESULT="$RESULT_FAIL"
fi

PKGS="NetworkManager-gnome control-center gdm gdm-user-switch-applet gnome-panel gnome-power-manager gnome-screensaver gnome-session gnome-terminal gvfs-archive gvfs-fuse gvfs-smb metacity nautilus notification-daemon polkit-gnome xdg-user-dirs-gtk yelp control-center-extra eog gdm-plugin-fingerprint gnome-applets gnome-media gnome-packagekit gnome-vfs2-smb gok orca vino"
DPKGS=""

for pkg in $PKGS; do
    grep -q "^$pkg[[:space:]]" $VALUE_RPM_QA && is_dist_native $pkg || continue
    test "$RESULT" = "$RESULT_FAIL" || log_high_risk "You have some of the Desktop group packages installed in your system. GNOME Desktop Environment that was provided by this group of packages underwent a serious redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7."
    DPKGS="$DPKGS $pkg"
    RESULT="$RESULT_FAIL"
done

rm -f solution.txt
# Generate solution.txt
if test "$RESULT" = "$RESULT_FAIL"; then
    echo "GNOME Desktop Environment as a part of the yum group 'Desktop' underwent a serious redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7. The users of the desktop environment need to be educated about these changes before the upgrade. GNOME classic user interface is provided in Red Hat Enterprise Linux 7 to minimize the impact of this change but the interface still contains several differences from the older version and the users need to be aware of them. More on the topic at [link:https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Desktop_Migration_and_Administration_Guide/index.html]" >> solution.txt
fi

if test -n "$DPKGS"; then
    echo "The following packages from yum group 'Desktop' that provides GNOME Desktop Environment were detected to be installed in your system:$DPKGS" >> solution.txt
fi
exit "$RESULT"
