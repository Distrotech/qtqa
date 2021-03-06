#############################################################################
##
## Copyright (C) 2015 The Qt Company Ltd.
## Contact: http://www.qt.io/licensing/
##
## This file is part of the Quality Assurance module of the Qt Toolkit.
##
## $QT_BEGIN_LICENSE:LGPL21$
## Commercial License Usage
## Licensees holding valid commercial Qt licenses may use this file in
## accordance with the commercial license agreement provided with the
## Software or, alternatively, in accordance with the terms contained in
## a written agreement between you and The Qt Company. For licensing terms
## and conditions see http://www.qt.io/terms-conditions. For further
## information use the contact form at http://www.qt.io/contact-us.
##
## GNU Lesser General Public License Usage
## Alternatively, this file may be used under the terms of the GNU Lesser
## General Public License version 2.1 or version 3 as published by the Free
## Software Foundation and appearing in the file LICENSE.LGPLv21 and
## LICENSE.LGPLv3 included in the packaging of this file. Please review the
## following information to ensure the GNU Lesser General Public License
## requirements will be met: https://www.gnu.org/licenses/lgpl.html and
## http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
##
## As a special exception, The Qt Company gives you certain additional
## rights. These rights are described in The Qt Company LGPL Exception
## version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
##
## $QT_END_LICENSE$
##
#############################################################################

package QtQA::PerlChecks;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( all_files_in_git all_perl_files_in_git );

use File::chdir;
use File::Spec::Functions;
use File::Find;
use List::MoreUtils qw( apply );
use Perl::Critic::Utils qw( all_perl_files );
use Test::More;

# Helper for tests in this directory to find perl files for testing.

# Returns a list of all files known to git under the given $path (or '.' if unset)
# It is considered a failure if there are no files known to git.
sub all_files_in_git
{
    my ($path) = @_;

    if (!$path) {
        $path = '.';
    }

    # Do everything from $path, so we get filenames relative to that
    local $CWD = $path;

    my $QT_MODULE_TO_TEST=$ENV{QT_MODULE_TO_TEST};

    # Find all the files known to git
    my @out;
    if (-d $QT_MODULE_TO_TEST . '/.git') {
        @out =
            apply { $_ = canonpath($_) } # make paths canonical ...
            apply { chomp }     # strip all newlines ...
                qx( git ls-files );
    } else {
        find(sub{ push @out, canonpath($File::Find::name); }, ".");
    }
    foreach (@out) {
        print "$_\n";
    }

    # Get files in a reliable order
    @out = sort @out;

    is( $?, 0, 'git ls-files ran ok' );
    ok( @out,  'git ls-files found some files' );

    return @out;
}

# Returns a list of all perl files known to git under the given $path.
# See Perl::Critic::Utils all_perl_files for documentation on what
# "perl files" means.
# May return an empty list if there are no perl files.
sub all_perl_files_in_git
{
    my ($path) = @_;

    if (!$path) {
        $path = '.';
    }

    # Do everything from $path, so we get filenames relative to that
    local $CWD = $path;

    # Find all the git files ...
    my %all_git_files = map { $_ => 1 } all_files_in_git( '.' );

    # Then return only those perl files which are also in git
    my @out = grep { $all_git_files{ $_ } } all_perl_files( '.' );

    # Get files in a reliable order
    @out = sort @out;

    return @out;
}

1;

