#-------------------------------------------------------------------------------
sub RegisterBounce($$$) {
    my ($email, $reason, $dbh, $level) = @_;
    print "BOUNCE: $email with reason $reason\n";
    
    my ($email_user, $email_domain) = split(/\@/, lc($email));
    unless ($email_user && $email_domain) {
        print "Invalid email address!\n";
        exit(1);
    }
    my $domain_id = RegisterBounceDomain($email_domain, $dbh);
    
    $level ||= ($reason eq 'over_quota') ? 'soft' : 'hard';
    RegisterBounceEmail($email_user, $domain_id, $reason, $level, $dbh);
}

#-------------------------------------------------------------------------------
sub RegisterBounceDomain($$) {
    my ($domain, $dbh) = @_;
    
    # Lookup domain name
    my $sth = $dbh->prepare("SELECT id FROM $domains_table WHERE name = ? AND name_crc32 = ?");
    $sth->execute($domain, crc32($domain));
    my $row = $sth->fetchrow_hashref;
    return $row->{id} if $row;

    # If not found, create it
    print "Registering domain: $domain\n";
    $sth = $dbh->prepare("INSERT INTO $domains_table (name, name_crc32) VALUES (?, ?)");
    $sth->execute($domain, crc32($domain));
    return $dbh->sqlite_last_insert_rowid()
}

#-------------------------------------------------------------------------------
sub RegisterBounceEmail($$$$$) {
    my ($email_user, $domain_id, $reason, $level, $dbh) = @_;
    
    my $sql = "
        INSERT INTO $blacklist_table (
          domain_id,
          user_crc32,
          user,
          source,
          level,
          reason,
          created_at)
          VALUES (
          ?,
          ?,
          ?,
          'bounce',
          ?,
          ?,
          date('now'))
    ";
    my $sth = $dbh->prepare($sql);
    $sth->execute($domain_id, crc32($email_user), $email_user, $level, $reason);
}

1;