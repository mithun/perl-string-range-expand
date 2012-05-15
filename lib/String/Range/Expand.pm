package String::Range::Expand;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '0.01';

#######################
# EXPORT
#######################
use base qw(Exporter);
our ( @EXPORT, @EXPORT_OK );

@EXPORT    = qw(expand_range);
@EXPORT_OK = qw(expand_range);

#######################
# PUBLIC FUNCTIONS
#######################
sub expand_range {
    my ($range_expr) = @_;

    my @range;

    # split expression into ranges
    my @bits;
    if ( $range_expr =~ m{\[[a-zA-Z0-9,\-\^\s]+\]} ) {

        # This is a Range
        # Loop thru' multiple instances (e.g. [a-c][f-i])
        while ( $range_expr =~ m{(\[[a-zA-Z0-9,\-\^\s]+\])}gc ) {

            # Collec pieces
            my $pre   = $`;
            my $match = $&;
            my $post  = $';

            # Clean them
            $pre   = _trim($pre)   if defined $pre;
            $match = _trim($match) if defined $match;
            $post  = _trim($post)  if defined $post;

            # Save Them
            push( @bits, $pre )
                if ( ( defined $pre ) and ( $pre !~ m{\[|\]} ) );
            push( @bits, $match ) if ( defined $match );
            push( @bits, $post )
                if ( ( defined $post ) and ( $post !~ m{\[|\]} ) );
        } ## end while ( $range_expr =~ m{(\[[a-zA-Z0-9,\-\^\s]+\])}gc)
    } ## end if ( $range_expr =~ m{\[[a-zA-Z0-9,\-\^\s]+\]})
    else {

        # Expression does not have any ranges to expand
        push @range, $range_expr;
    }

    # Do we need to expand anything?
    return @range if not @bits;

    # Expand
    foreach my $_bit (@bits) {
        if ( $_bit =~ m{^\[(.+)\]$} ) {
            @range
                ? ( @range = _combine( \@range, [ _compute($1) ] ) )
                : ( @range = _compute($1) );
        }
        else {
            @range
                ? ( @range = _combine( \@range, [$_bit] ) )
                : ( push( @range, $_bit ) );
        }
    } ## end foreach my $_bit (@bits)

    return @range;
} ## end sub expand_range

#######################
# INTERNAL FUNCTIONS
#######################

## _compute
##  This performs the actual expansion
sub _compute {
    my ($expr) = @_;

    my @list;  # Expanded values

    # Loop thru' ranges
    foreach my $_range ( split( /,/, $expr ) ) {
        $_range = _trim($_range);  # Cleanup

        # Type: [aa-az]. Normal Range
        if ( $_range =~ m{^(\w+)\-(\w+)$} ) { push @list, ( $1 .. $2 ); }

        # Type: [^ba-be]. Negate range
        elsif ( $_range =~ m{^\^(\w+)\-(\w+)$} ) {
            foreach my $_exclude ( $1 .. $2 ) {
                @list = grep { !/^$_exclude$/ } @list;
            }
        }

        # Type: [^zz]. Negate element
        elsif ( $_range =~ m{^\^(\w+)$} ) {
            @list = grep { !/^$1$/ } @list;
        }

        # Type: [foo]. Individual element
        else { push @list, $_range; }
    } ## end foreach my $_range ( split(...))
    return @list;
} ## end sub _compute

## _combine
sub _combine {
    my ( $a1, $a2 ) = @_;

    my @list;

    foreach my $_a1 (@$a1) {
        foreach my $_a2 (@$a2) {
            push @list, join( '', $_a1, $_a2 );
        }
    }

    return @list;
} ## end sub _combine

## _trim
#   "borrowed" from Text::Trim
sub _trim {
    my ($_str) = @_;
    return unless defined $_str;
    $_str =~ s{\A\s+}{};
    $_str =~ s{\s+\z}{};
    return $_str;
} ## end sub _trim

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

String::Range::Expand - Expand range-like strings

=head1 SYNOPSIS

    use String::Range::Expand;

    print "$_\n" for expand_range('host[aa-ac,^ab,ae][01-04,^02-03]');

    # Prints ...
        # hostaa01
        # hostaa04
        # hostac01
        # hostac04
        # hostae01
        # hostae04

=head1 DESCRIPTION

=head1 DEPENDENCIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-string-range-expand@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=String-Range-Expand>

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut
