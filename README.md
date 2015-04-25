# OpenDirectoryMigrationUtility
This utility aids in the migration of Apple's Open Directory LDAP by resetting user passwords and sending email notifications.  This way it doesn't matter if your new OD server has the same name.

Overview
--------
If you are attempting to migrate Open Directory from one server to another
and don't want to keep the same name of your server this might be of use to
you.

The caveat is that this technique requires users to experience a password reset.

The good news is that this utility also automatically sends out email notifications
so users know that they have had their password changed.

It uses Perl to iterate through your Open Directory on your Apple Open Directory 
Server.

Pre-requisites
--------------
Mavericks comes by default with Net::LDAP and use Net::LDAP::Extension::SetPassword
but does not come with use Net::SMTP::SSL

Net::SMTP::SSL is a Perl Module used to send emails using SSL.  The script is
set to use Google as the SMTP server so you will need to adjust it to work with
your mail servers if you aren't using Google.

To install Net::SMTP::SSL under OS X 10.9.5 Mavericks, follow these steps:

Open the Terminal app and type these commands followed by the <return> key:

$ sudo perl -MCPAN -e "shell"

When prompted whether you want automatic configuration, answer 'yes'.

If prompted how you want to install the system may ask about a lib or sudo...
type 'sudo' and hit <return>.

At the CPAN> prompt type the following and then hit <return>:

> install Net::SMTP::SSL

When it finishes, type exit and hit <return>.

Configuring
-----------
Before you run the scripts it is a good idea to configure them to work with your
environment.

Change the lines 15 and 16 of the notification-email.pl script to set your sender
account email address and password.

Change the variables on lines 22-44 for your environments.

There is a variable called $stage where you set whether you are running the script
for a 'dev' or 'prod' environment.

You need to know your environment to get this working.  It's pretty rough but, it's 
working for me.

Running
-------
Once your scripts are configured, run:

perl oditerator.pl
