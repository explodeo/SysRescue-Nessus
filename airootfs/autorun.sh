#!/bin/sh

DOD_LOGIN_BANNER="You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.\nBy using this IS (which includes any device attached to this IS), you consent to the following conditions:\n-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.\n-At any time, the USG may inspect and seize data stored on this IS.\n-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.\n-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.\n-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details."

# setup root login with ssh keys
ssh-keygen -A
echo -e '\n\n\n' | ssh-keygen -t rsa
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

# Configure Nessus
# Set configuration options for nessus programmatically
echo -e 'acasuser\nacasuser\ny\n\ny\n' | /opt/nessus/sbin/nessuscli adduser acasuser
systemctl stop nessusd.service
echo -e 'y\n' | /opt/nessus/sbin/nessuscli fix --reset
/opt/nessus/sbin/nessuscli fetch --security-center
/opt/nessus/sbin/nessuscli fix --set path_to_java=/bin/java
/opt/nessus/sbin/nessuscli fix --set xml_enable_plugin_attributes=yes
/opt/nessus/sbin/nessuscli fix --set severity_basis=cvss_v4
/opt/nessus/sbin/nessuscli fix --set login_banner="$DOD_LOGIN_BANNER"
/opt/nessus/sbin/nessuscli fix --set ui_theme=dark
systemctl start nessusd.service
exit 0