package Snail::CSV;

use strict;
use Text::CSV_XS;
use IO::File;

use vars qw($VERSION);
$VERSION = '0.01';

sub new
{
	my $class = shift;
	my $this = bless {}, $class;

	$this->{'OPTS'} = shift || {};
	unless ( %{$this->{'OPTS'}} )
	{
		$this->{'OPTS'} = { 'eol' => "\015\012", 'sep_char' => ';', 'quote_char'  => '"', 'escape_char' => '"', 'binary' => 1 }
	}
	return $this;
}

sub setFile
{
	my $this = shift;
	$this->{'FILE'} = shift;
	$this->{'FIELDS'} = shift || [];
	$this->{'FILTER'} = shift || {};

	$this->{'DATA'} = [];

	$this->{'FILE'} or die "Please provide a filename to parse\n";
	-f $this->{'FILE'} or die "Cannot find filename: ". $this->{'FILE'}. "\n";

	return $this;
}

sub parse
{
	my $this = shift;
	if (exists($this->{'DATA'}) && @{$this->{'DATA'}}) { return $this->{'DATA'}; }
	exists($this->{'FILE'}) or die "Please provide a filename to parse\n";
	exists($this->{'CSVXS'}) or $this->_init_csv;

	$this->{'DATA'} = [];

	{
		local $/ = $this->{'OPTS'}->{'eol'} || "\015\012";

		my $fh = new IO::File;
		if ($fh->open("< $this->{'FILE'}"))
		{
			while (my $columns = $this->{'CSVXS'}->getline($fh))
			{
				last unless @{$columns};
				my $tmpout = {};
				my $filter_flag = 1;
				for (my $j = 0; $j < @{$columns}; $j++)
				{
					my $colname = $this->{'FIELDS'}->[$j] ? $this->{'FIELDS'}->[$j] : "";
					next unless $colname;

					$tmpout->{$colname} = $columns->[$j];
					if (exists($this->{'FILTER'}->{$colname}) && ref $this->{'FILTER'}->{$colname} eq 'CODE')
					{
						$filter_flag = $this->{'FILTER'}->{$colname}->($tmpout->{$colname});
					}
					if (exists($this->{'FILTER'}->{$colname}) && ref $this->{'FILTER'}->{$colname} eq 'SCALAR')
					{
						$filter_flag = $this->{'FILTER'}->{$colname} eq $tmpout->{$colname} ? 1 : 0;
					}
				}
				if ($filter_flag) { push @{$this->{'DATA'}}, $tmpout; }
			}
			$fh->close;
		}
	}
	return $this->{'DATA'};
}

sub getData
{
	my $this = shift;
	return exists($this->{'DATA'}) ? $this->{'DATA'} : [];
}

sub _init_csv
{
	my $this = shift;
	$this->{'CSVXS'} = Text::CSV_XS->new( $this->{'OPTS'} );
	return $this;
}

sub version { return $VERSION; }

1;

=head1 NAME

Snail::CSV - Perl extension for read CSV files.

=head1 SYNOPSIS

  use Snail::CSV;
  my $csv = Snail::CSV->new(\%args);	# %args - Text::CSV_XS options


  $csv->setFile("lamps.csv", [ "id", "name", "pq" ]);


  my $lamps = $csv->parse;

  # or

  $csv->parse;
  # some code
  my $lamps = $csv->getData;


  $csv->setFile("tents.csv", [ "id", "name", "brand", "price" ]);


  my $tents = $csv->parse;


=head1 DESCRIPTION

This module can be used to read data from CSV files. L<Text::CSV_XS> is used for parsing CSV files.

=head1 METHOD

=over

=item B<new()>

=item B<new(\%args)>

This is constructor. %args - L<Text::CSV_XS> options. Return object.

=item B<setFile('file.csv', \@fields_name)>

=item B<setFile('file.csv', \@fields_name, \%filters)>

Set CSV file, fields name and filters for fields name. Return object.

Fields and Filters:

  my @fields_name = ("id", "name", "pq");
  my %filters = (
                 'pq'   => 3,
                 'name' => sub { my $name = shift; $name =~ /XP$/ ? 1 : 0; }
                );

=item B<parse>

Read and parse CSV file. Return arrayref.

=item B<getData>

Return arrayref. Use this method after B<parse>.

=item B<version>

Return version number.

=back

=head2 EXPORT

None by default.



=head1 EXAMPLE

Code:

  #!/usr/bin/perl -w
  use strict;

  use Snail::CSV;
  use Data::Dumper;

  my $csv = Snail::CSV->new();

  $csv->setFile("lamps.csv", [ "id", "name", "pq" ]);
  # or
  $csv->setFile("lamps.csv", [ "id", "", "pq" ], { 'pq' => sub { my $pq = shift; $pq > 2 ? 1 : 0; } });

  my $lamps = $csv->parse;

  print Dumper($lamps);

lamps.csv

  1;"Tikka Plus";3
  2;"Myo XP";1
  3;"Duobelt Led 8";5

If you wrote:

  $csv->setFile("lamps.csv", [ "id", "name", "pq" ]);

then C<dump> is:

  $VAR1 = [
          {
            'id'   => '1',
            'name' => 'Tikka Plus',
            'pq'   => '3'
          },
          {
            'id'   => '2',
            'name' => 'Myo XP',
            'pq'   => '1'
          },
          {
            'id'   => '3',
            'name' => 'Duobelt Led 8',
            'pq'   => '5'
          }
        ];

But if:

  $csv->setFile("lamps.csv", [ "id", "", "pq" ], { 'pq' => sub { my $pq = shift; $pq > 2 ? 1 : 0; } });

C<dump> is:

  $VAR1 = [
          {
            'id'   => '1',
            'pq'   => '3'
          },
          {
            'id'   => '3',
            'pq'   => '5'
          }
        ];

=head1 SEE ALSO

L<Text::CSV_XS>, L<IO::File>

=head1 AUTHOR

Dmitriy Dontsov, E<lt>mit@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dmitriy Dontsov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
