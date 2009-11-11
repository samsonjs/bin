#!/usr/bin/perl -w
use strict;

sub mail_status {
    $date = `date +%Y%m%d-%h:%m`;
    open(MAIL, "|/usr/lib/sendmail -t");
    print MAIL "To: $info{to}\n";
    print MAIL "From: $info{from}\n";
    print MAIL "Subject: $info{host} status report for $date\n";
    print MAIL "$info{host} has been up:\n$info{uptime}\n\n";
    print MAIL "memory usage (mb):\n$info{mem}\n\n";
    print MAIL "disk usage:\n$info{disk}\n\n";
    print MAIL "service status:\n$info{services}\n\n";
    close (MAIL);
}

my ($year, $month, $day) = (`date +%Y`, `date +%m`, `date +%d`);
my $logDir = "/var/log";
my @logFiles = qw( messages apache2/access_log apache2/error_log );
my @targetFiles = qw( messages apache_access apache_error );
my $remoteHost = "home.nofxwiki.net";
my $remoteDir = "/home/sjs/log/nofxwiki.net/$year/$month";
my $filePrefix = "$day-";
my @services = qw( apache2 clamd courier-authlib courier-imapd courier-imapd-ssl iptables mysql spamd sshd );

my $file;
my $remoteFile;
for (my $i = 0; $i < @logFiles; $i++) {
    $file = $logFiles[$i];
    $remoteFile = $torgetFiles[$i];
    open $file, "tail -f $logDir/$file |" \
        or die "Could not open 'tail -f $file', bailing!\n";
    open "ssh-$file", "| ssh $remoteHost 'cat >> $remoteDir/$remoteFile'" \
        or die "Could not open 'ssh $remoteHost 'cat >> $remoteDir/$remoteFile\n'', bailing!\n";
}

my $ticks = 0;
my %info;
while (1) {
    foreach my $file (@logFiles) {
        while (my $line = <$file>) {
            print "ssh-$file" $lines;
        }
    }
    
    sleep 300;      # 5 minutes
    $ticks++;
    if ($ticks == 72) {     # 360 min = 6 hr
        $ticks = 0;
        $info{host} = `hostname --fqdn`;
        $info{uptime} = `w`;
        $info{mem} = `free -m`;
        $info{disk} = `df -h`;

        foreach my $svc (@services) {
            open SVC, "/etc/init.d/$svc status |";
            @info{services} += <SVC>;
            close SVC;
        }
        &mail_status(%info);
    }
}