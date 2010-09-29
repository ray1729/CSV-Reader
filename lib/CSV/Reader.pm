package CSV::Reader;

# ABSTRACT: wrapper around Text::CSV_XS to reduce boilerplate when reading CSV files

use Moose;
use MooseX::Types::IO 'IO';
use Text::CSV_XS;
use namespace::autoclean;

has input => (
    is       => 'ro',
    isa      => 'IO',
    coerce   => 1,
    default  => sub { IO::Handle->new_from_fd( \*STDIN, 'r' ) }
);

has csv_opts => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { eol => $/ } }
);

has columns => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_columns',
    writer    => '_set_columns',
);

has use_header => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has skip_header => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has _csv => (
    is       => 'rw',
    isa      => 'Text::CSV_XS',
    init_arg => undef,
    handles  => [ 'eof' ]
);


sub BUILD {
    my $self = shift;

    confess "only one of use_header or skip_header may be specified"
        if $self->use_header and $self->skip_header;

    confess "only one of use_header or columns may be specified"
        if $self->use_header and $self->has_columns;    
    
    my $csv = Text::CSV_XS->new( $self->csv_opts );

    if ( $self->use_header ) {
        $self->_set_columns( $csv->getline( $self->input ) );
    }

    if ( $self->skip_header ) {
        $csv->getline( $self->input );
    }
        
    if ( $self->has_columns ) {
        $csv->column_names( $self->columns );
    }

    $self->_csv( $csv );
}

sub read {
    my $self = shift;

    my $data;

    if ( $self->has_columns ) {
        $data = $self->_csv->getline_hr( $self->input );
    }
    else {
        $data = $self->_csv->getline( $self->input );
    }

    confess sprintf( "failed to parse '%s': %s", $self->_csv->error_input || '', ''.$self->_csv->error_diag )
        unless $data or $self->eof;

    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

CSV::Reader

=head1 SYNOPSIS

  use CSV::Reader;

  my $csv = CSV::Reader->new( use_header => 1 );
  my $href = $csv->read;

=head1 DESCRIPTION

Wrapper around Text::CSV_XS to reduce boilerplate when reading CSV files.

=head1 METHODS

=head2 new

Constructor, accepts a hash ref or list of key/value pairs:

=over 4

=item input

The filename or L<IO::Handle> object that output will be read from.

=item csv_opts

A hash reference of options for the L<Text::CSV_XS> constructor.

=item columns

Reference to a list of column names (in the order they appear in the
input); if this option is specified, read() will return a hash
reference keyed on the specified columns.

=item use_header

Boolean (default: false). If set to true, the first line of input will
be parsed and used to set the column names.

=item discard_header

Boolean (default: false). If set to true, the first line of input will be
read and discarded.

=back

=head2 read

Read and parse the next line of input. If I<columns> or I<use_header>
was specified in the constructor, will return a hash reference keyed
on I<columns>, otherwise will return an array reference.

=head1 SEE ALSO

L<Text::CSV_XS>, L<Moose>, L<MooseX::Types::IO>

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=head1 BUGS

None reported...yet!

=cut
