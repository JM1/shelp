#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup user dirs with Apache2
#
#      Url: http://hostname/~_USER_/
#  Example: http://hostname/~johnwayne/
#

USERNAME=johnwayne
cat << EOF | patch
--- /etc/apache2/mods-available/userdir.conf.orig    2015-10-24 10:37:19.000000000 +0200
+++ /etc/apache2/mods-available/userdir.conf    2016-02-06 23:51:28.386066125 +0100
@@ -1,6 +1,7 @@
 <IfModule mod_userdir.c>
 	UserDir public_html
-	UserDir disabled root
+	UserDir disabled
+	UserDir enabled $(USERNAME)
 
 	<Directory /home/*/public_html>
 		AllowOverride FileInfo AuthConfig Limit Indexes
@@ -12,6 +13,42 @@
 			Require all denied
 		</LimitExcept>
 	</Directory>
+
+	# 2016 Jakob Meng, <jakobmeng@web.de>
+	# Erlaube das Überschreiben der Options.
+	# Ist nützlich um php Werte überschreiben zu können, um bspw. das Debuggen zu aktivieren
+	<Directory /home/$(USERNAME)/public_html/>
+		AllowOverride FileInfo AuthConfig Limit Indexes Options
+
+		# Options müssen hier noch irgendwie eingeschränkt werden! Ich will dem Benutzer nur
+		# erlauben, die Debugfunktionen zu aktivieren
+		# Folgendes hat keine Wirkung: Options -ExecCGI +IncludesNoExec
+		# "Lösung": Mithilfe eines Location-Tags kann man die Options überschreiben!
+	</Directory>
+
+	#Überschreibung der Options aus dem "AllowOverride" des Directory-Tags weiter oben.
+	<Location /~$(USERNAME)/>
+		Options -All
+
+		# !!! Wichtig: 	Es ist trotzdem möglich Optionen (bspw. php_value) weiterhin 
+		#		zu überschreiben, eventuell ein Sicherheitloch!
+
+	</Location>
+
+	# 2016 Jakob Meng, <jakobmeng@web.de>
+	# Erlaube auch CGI-Skripte
+	<Directory /home/*/public_html/cgi-bin/>
+		Options ExecCGI
+		SetHandler cgi-script
+	</Directory>
+	
+	# Hide the cgi-bin/src/ directory
+	<Directory /home/*/public_html/cgi-bin/src/>
+		Order allow,deny
+		Deny from all
+		Satisfy all
+	</Directory>
+
 </IfModule>
 
 # vim: syntax=apache ts=4 sw=4 sts=4 sr noet

EOF

exit # the end
