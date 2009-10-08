use strict;
use warnings;

use Module::Build 0.28;

# This is so that I can automagically generate the Changes file from
# git.
my $class = Module::Build->subclass(
    code => << 'END' );

use File::Spec;

sub ACTION_dist {
    my $self = shift;
    my $dist_dir = $self->dist_dir;

    {
        # If needed, we'll sign it ourselves
        local $self->{properties}{sign} = 0;
        $self->depends_on('distdir') unless -d $self->dist_dir;
    }

    unless (eval { require Git; 1 }) {
        $self->log_warn("Couldn't load Git for 'dist' action:\n $@\n");
        return;
    }

    {
        my $manifest = File::Spec->catfile($dist_dir, 'MANIFEST');
        die "Making dist requires a MANIFEST file" unless -e $manifest;
        $self->_add_to_manifest($manifest, "Changes    Added here by ".ref($self));
    }
    my $changes_fn = File::Spec->catfile($dist_dir,"Changes");

    open my $Changes, '>', $changes_fn
        or die "Failed to open Changes file for writing: $!";

    {
        my $repo = Git->repository();

        my ($log_fh, $ctx) = $repo->command_output_pipe('log', '--no-color',
            '--abbrev', '--shortstat');

        print $Changes $_ while (<$log_fh>);
        $repo->command_close_pipe($log_fh, $ctx);
    }

    print $Changes "\n# vim: set ft=git :\n";
    close $Changes;

    $self->_sign_dir($dist_dir) if $self->{properties}{sign};

    return $self->SUPER::ACTION_dist(@_);
}
END

my $build = $class->new(
    module_name     => 'Remind::Client',
    license         => 'perl',
    sign            => 1,
    configure_requires  => {
        'Module::Build' => 0.28, # for meta_merge
    },
    build_requires  => {
        'File::Temp' => 0.14, # for tests
        'Module::Build' => 0.28,
        'POSIX' => 0, # for tests
        'Test::More' => 0.81_01, # for note()
        'Test::NoWarnings' => 0,
        'Test::Warn' => 0,
    },
    requires => {
        'Carp' => 0,
        'File::HomeDir' => 0.50,
        'IO::Handle' => 0,
        'IPC::Open2' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://git.pioto.org/gitweb/Remind-Client.git',
            license => 'http://dev.perl.org/licenses/',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Remind-Client',
        },
    },
);
$build->create_build_script();

