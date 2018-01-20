package App::RunMatrix;
use strict;
use warnings;

use App::cpm;
use Capture::Tiny 'capture';
use Config;
use Cwd ();
use File::Spec;
use Module::Metadata;
use Process::Status;

use constant CYAN => 36;
use constant GREEN => 32;
use constant RED => 31;
use constant YELLOW => 33;

our $VERSION = '0.001';

sub new {
    my $class = shift;
    bless { color => -t STDOUT }, $class;
}

sub show_help {
    my $self = shift;
    require Pod::Usage;
    Pod::Usage::pod2usage(0);
}

sub info {
    my $self = shift;
    my $color = shift || CYAN;
    my $msg = @_ > 1 ? sprintf shift, @_ : $_[0];
    if ($self->{color}) {
        warn "\e[${color}m> $msg\e[m\n";
    } else {
        warn "$msg\n";
    }
}

sub err {
    my $self = shift;
    my $color = shift || RED;
    my $msg = @_ > 1 ? sprintf shift, @_ : $_[0];
    if ($self->{color}) {
        die "\e[${color}m> $msg\e[m\n";
    } else {
        die "$msg\n";
    }
}

sub system : method {
    my ($self, $module, $version, @cmd) = @_;
    local %ENV = %ENV;
    if ($version !~ /^(default|core|system)$/) {
        if (my @lib = $self->local_lib($module, $version)) {
            push @lib, $ENV{PERL5LIB} if $ENV{PERL5LIB};
            $ENV{PERL5LIB} = join ":", @lib;
        }
    }
    system {$cmd[0]} @cmd;
    Process::Status->new($?);
}

sub run {
    my $self = shift;
    $self->show_help if @_ and $_[0] =~ /^(-h|--help)$/;

    my ($spec, @cmd) = @_;
    my ($module, @version) = $self->_parse_spec($spec);

    my $installed;
    for my $version (@version) {
        next if $version =~ /^(default|core|system)$/;
        next if $self->_is_installed($module, $version);
        $self->info(CYAN, "Installing $module\@$version");
        $self->_install($module, $version)
            or $self->err(RED, "Failed to install $module\@$version, see ~/.perl-cpm/build.log");
        $installed++;
    }
    warn "\n" if $installed;

    my $fail;
    for my $i (0 .. $#version) {
        warn "\n" if $i != 0;
        my $version = $version[$i];
        $self->info(CYAN, "Run command against $module\@$version");
        my $status = $self->system($module, $version, @cmd);
        my $color = $status->is_success ? GREEN : RED;
        $self->info($color, "Fisnished with exit status %d", $status->exitstatus);
        $fail++ unless $status->is_success;
        last if $status->signal;
    }
    $fail ? 1 : 0;
}

sub local {
    my ($self, $module, $version) = @_;
    my $identity = "perl-$Config{version}";
    $module =~ s{::}{-}g;
    File::Spec->catdir(".run-matrix", $identity, "$module-$version");
}

sub local_lib {
    my ($self, $module, $version) = @_;
    my $local = $self->local($module, $version);
    map { Cwd::abs_path($_) } grep { -d $_ } (
        File::Spec->catdir($local, "lib/perl5"),
        File::Spec->catdir($local, "lib/perl5/$Config{archname}"),
    );
}

sub _parse_spec {
    my ($self, $spec) = @_;
    if ($spec =~ s/:([^:]+)$//) {
        my $module = $spec;
        my $version = $1;
        ($module, split /,/, $version);
    } else {
        $self->err(RED, "Failed to parse spec $spec");
    }
}

sub _install {
    my ($self, $module, $version) = @_;
    my ($out, $err, $exit) = capture {
        local @INC = @INC;
        local %ENV = %ENV;
        App::cpm->new->run("install",
            "--no-show-progress",
            "--no-color",
            "-L" => $self->local($module, $version),
            "$module\@$version",
        );
    };
    $exit == 0;
}

sub _is_installed {
    my ($self, $module, $version) = @_;
    my @lib = $self->local_lib($module, $version);
    my $metadata = Module::Metadata->new_from_module($module, inc => [@lib, @INC]);
    return unless $metadata;
    $metadata->version == $version;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::RunMatrix - run commands against module version matrix

=head1 SYNOPSIS

  $ run-matrix File::Temp:0.22,0.23 perl eg/file-temp.pl
  > Installing File::Temp@0.22
  > Installing File::Temp@0.23

  > Run command against File::Temp@0.22
  /tmp/il2wVVO7gB
  > Fisnished with exit status 0

  > Run command against File::Temp@0.23
  test-DlRrJ
  > Fisnished with exit status 0

=head1 DESCRIPTION

App::RunMatrix runs commands against module version matrix.

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
