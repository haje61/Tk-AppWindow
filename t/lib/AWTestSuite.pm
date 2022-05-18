package AWTestSuite;

use strict;
use warnings;
use Test::More;
use Tk;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	CreateTestApp
	ListCompare
	$app
	$mwclass
	@tests
	$show
	$settingsfolder
);

our $app;
our $mwclass = 'Tk::AppWindow';
our @tests = ();
our $show = 0;
our $settingsfolder = 't/settings';


my $arg = shift @ARGV;
$show = 1 if (defined($arg) and ($arg eq 'show'));

sub CreateTestApp {
	eval "use $mwclass";
	$app = new $mwclass(
		-width => 200,
		-height => 125,
		-appname => 'TestSuite',
		@_
	);
	ok(defined $app, "can create");
	$app->after(10, \&DoTests);
}

sub DoTests {
	ok(1, "main loop runs");
	for (@tests) {
		my ($call, $expected, $comment) = @$_;
		my $result = &$call;
		if ($expected =~ /^ARRAY/) {
			ok(ListCompare($expected, $result), $comment)
		} elsif ($expected =~ /^HASH/) {
			ok(HashCompare($expected, $result), $comment)
		} else {
			ok(($expected eq $result), $comment)
		}
	}
	$app->after(5, sub { $app->CommandExecute('quit') }) unless $show
}

sub HashCompare {
	my ($h1, $h2) = @_;
	my @l1 = sort keys %$h1;
	my @l2 = sort keys %$h2;
	return 0 unless ListCompare(\@l1, \@l2);
	for (@l1) {
		my $test1 = $h1->{$_};
		unless (defined $test1) { $test1 = 'UNDEF' }
		my $test2 = $h2->{$_};
		unless (defined $test2) { $test2 = 'UNDEF' }
		if ($test1 =~ /^ARRAY/) {
			return 0 unless ListCompare($test1, $test2)
		} elsif ($test1 =~ /^HASH/) {
			return 0 unless HashCompare($test1, $test2)
		} else {
			return 0 if $test1 ne $test2
		}
	}
	return 1
}

sub ListCompare {
	my ($l1, $l2) = @_;
# 	use Data::Dumper; print Dumper $l2;
	my $size1 = @$l1;
	my $size2 = @$l2;
	if ($size1 ne $size2) { return 0 }
	foreach my $item (0 .. $size1 - 1) {
		my $test1 = $l1->[$item];
		unless (defined $test1) { $test1 = 'UNDEF' }
		my $test2 = $l2->[$item];
		unless (defined $test2) { $test2 = 'UNDEF' }
		if ($test1 =~ /^ARRAY/) {
			return 0 unless ListCompare($test1, $test2)
		} elsif ($test1 =~ /^HASH/) {
			return 0 unless HashCompare($test1, $test2)
		} else {
			return 0 if $test1 ne $test2
		}
	}
	return 1
}


1;
