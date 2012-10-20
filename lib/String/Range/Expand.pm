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
our $VERSION = '0.02';

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

    # Define a valid range
    my $valid_range = qr{[a-zA-Z0-9\,\-\^]+}x;

    # split expression into ranges
    my @bits;
    if ( $range_expr =~ m{\[$valid_range\]}x ) {

        # This is a Range
        # Loop thru' multiple instances (e.g. [a-c][f-i])
        while (1) {

            if ( $range_expr =~ m{(\[$valid_range\])}x ) {
                my $match = $+;
                my $pre = substr( $range_expr, 0, $-[0] );
                push @bits, ($pre) if defined $pre;
                push @bits, $match;
                substr( $range_expr, 0, $+[0], '' );
            } ## end if ( $range_expr =~ m{(\[$valid_range\])}x)
            else {
                push @bits, $range_expr;
                $range_expr = '';
            }
            last unless $range_expr;

        } ## end while (1)
    } ## end if ( $range_expr =~ m{\[$valid_range\]}x)
    else {

        # Expression does not have any ranges to expand
        push @range, $range_expr;
    }

    # Expand
    foreach my $_bit (@bits) {
        if ( $_bit =~ m{^\[(.+)\]$}x ) {
            @range
                ? do { @range = _combine( \@range, [ _compute($1) ] ); }
                : do { @range = _compute($1); };
        }
        else {
            @range
                ? do { @range = _combine( \@range, [$_bit] ); }
                : do { push( @range, $_bit ); };
        }
    } ## end foreach my $_bit (@bits)

    @range = sort { lc($a) cmp lc($b) } @range if @range;
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
    foreach my $_range ( split( /,/x, $expr ) ) {

        # Type: [aa-az]. Normal Range
        if ( $_range =~ m{^(\w+)\-(\w+)$}x ) { push @list, ( $1 .. $2 ); }

        # Type: [^ba-be]. Negate range
        elsif ( $_range =~ m{^\^(\w+)\-(\w+)$}x ) {
            foreach my $_exclude ( $1 .. $2 ) {
                @list = grep { !/^$_exclude$/x } @list;
            }
        }

        # Type: [^zz]. Negate element
        elsif ( $_range =~ m{^\^(\w+)$}x ) {
            @list = grep { !/^$1$/x } @list;
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

This module provides functions to expand a string that contains range-like
expressions. This is something that is usually useful when working with
hostnames, but can be used elsewhere too.

=head1 FUNCTIONS

=head2 expand_range($string)

    my @list = expand_range('...');

This function accept a single string, evaluates expressions in those strings
and returns a list with all avaialble permutations. Ranges with limits are
expanded using the L<Range
Operator|http://perldoc.perl.org/perlop.html#Range-Operators>.

    my @list = expand_range('[aa-ad]'); # This is identical to ('aa' .. 'ad')

The following formats are recognized and evaluated

    my @list = expand_range('foo[bar,baz]');        # Comma separated list
    my @list = expand_range('foo[aa-ad,^ab]');      # Negated element
    my @list = expand_range('foo[aa-ag,^ab-ad]');   # Negated range


=head1 SEE ALSO

=over

=item L<SSH::Batch>

This is an extremely useful distribution if you are working with hostnames.
C<String::Range::Expand> was inspired by this distribution, and provides only a
subset of features of C<SSH::Batch>

=item L<String::Glob::Permute>

Pretty similar, but does not evaluate alphabetical ranges

=item L<Text::Glob::Expand>

Like C<String::Glob::Permute>, it does not evaluate alphabetical ranges. But it
does provide some additional functionality like setting upper limits and
formatting.

=back

=head1 BUGS AND LIMITATIONS

This module does not attempt to limit the number of permutations for an
expression.

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
