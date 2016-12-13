#! /usr/bin/env bash

. /usr/share/preupgrade/common.sh

#END GENERATED SECTION
# We need to have Xorg installed to check for presence of any available gnome sessions

RESULT="$RESULT_PASS"
if test -f /usr/share/xsessions/kde.desktop; then
    log_extreme_risk "You have the KDE Desktop Environment session as an option in your X11 session manager. KDE Desktop Environment as a part of the yum group 'KDE Desktop' underwent a redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7."
    RESULT="$RESULT_FAIL"
fi

PKGS="kde-settings-pulseaudio kdeaccessibility kdeartwork-screensavers kdebase kdebase-workspace kdelibs xsettings-kde k3b kcoloredit kdeadmin kdegames kdegraphics kdemultimedia kdenetwork kdepim kdepim-runtime kdeplasma-addons kdeutils kdm kiconedit kipi-plugins kmid konq-plugins ksig ksshaskpass pinentry-qt kdebase-workspace-akonadi kdebase-workspace-python-applet ibus-qt"
DPKGS=""

for pkg in $PKGS; do
    grep -q "^$pkg[[:space:]]" $VALUE_RPM_QA && is_dist_native $pkg || continue
    test "$RESULT" = "$RESULT_FAIL" || log_high_risk "You have some of the KDE Desktop yum group packages installed in your system. KDE Desktop Environment that was provided by this group of packages underwent a redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7."
    DPKGS="$DPKGS $pkg"
    RESULT="$RESULT_FAIL"
done

rm -f solution.txt
# Generate solution.txt
if test "$RESULT" = "$RESULT_FAIL"; then
    echo "KDE Desktop Environment as a part of the yum group 'KDE Desktop' underwent a redesign in its user interface as well as in underlying technologies in Red Hat Enterprise Linux 7. The users of the desktop environment need to be educated about these changes before the upgrade." >> solution.txt
fi

if test -n "$DPKGS"; then
    echo "The following packages from yum group 'KDE Desktop' that provides KDE Desktop Environment were detected to be installed in your system:$DPKGS" >> solution.txt
fi
exit "$RESULT"
