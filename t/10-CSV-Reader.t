#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use CSV::Reader;
use File::Temp;
use Readonly;

my $csv_file = File::Temp->new;
while ( <DATA> ) {
    $csv_file->print( $_ );    
}
$csv_file->close;

{
    ok my $r = CSV::Reader->new( input => $csv_file->filename ), 'constructor';
    isa_ok $r, 'CSV::Reader', '...the object it returns';
    ok my $d = $r->read, 'read() should succeed';
    isa_ok $d, 'ARRAY', '...the item it returns';
    is_deeply $d, [qw(foo bar baz)], 'read returns header';    
    is_deeply $r->read, [1,2,3], '...first line parses correctly';
    is_deeply $r->read, [4,5,6], '...second line parses correctly';
    is_deeply $r->read, [7,8,9], '...third line parses correctly';
    ok !defined($r->read), 'returns undef on eof';
    ok $r->eof, 'reached eof';
}

{
    ok my $r = CSV::Reader->new( input => $csv_file->filename, skip_header => 1 ), 'constructor with skip_header';
    ok my $d = $r->read, 'read() should succeed';
    isa_ok $d, 'ARRAY', '...the item it returns';
    is_deeply $d, [1,2,3], '...skipped header';
}

{
    ok my $r = CSV::Reader->new( input => $csv_file->filename, use_header => 1 ), 'constructor with use_header';
    ok my $d = $r->read, 'read() should succeed';
    isa_ok $d, 'HASH', '...the item it returns';
    is_deeply $d, { foo => 1, bar => 2, baz => 3 }, '...the first data item';
}

{
    ok my $r = CSV::Reader->new( input => $csv_file->filename, columns => [ 'a', 'b', 'c' ], skip_header => 1 ), 'constructor with columns';
    ok my $d = $r->read, '...read() should succeed';
    isa_ok $d, 'HASH', '...the item it returns';
    is_deeply $d, {a => 1, b => 2, c => 3 }, '...the first data item';
}

throws_ok { CSV::Reader->new( use_header => 1, skip_header => 1 ) }
    qr/only one of use_header or skip_header may be specified/;

throws_ok { CSV::Reader->new( use_header => 1, columns => [qw(a b c)] ) }
    qr/only one of use_header or columns may be specified/;

throws_ok { CSV::Reader->new( input => \"dodgy\a\013\014,string\n" )->read }
    qr/failed to parse/;


done_testing();

__DATA__
foo,bar,baz
1,2,3
4,5,6
7,8,9
