[![Build Status](https://travis-ci.org/skaji/App-RunMatrix.svg?branch=master)](https://travis-ci.org/skaji/App-RunMatrix)

# NAME

App::RunMatrix - run commands against module version matrix

# SYNOPSIS

    $ run-matrix File::Temp:0.22,0.23 perl eg/file-temp.pl
    > Installing File::Temp@0.22
    > Installing File::Temp@0.23

    > Run command against File::Temp@0.22
    /tmp/il2wVVO7gB
    > Fisnished with exit status 0

    > Run command against File::Temp@0.23
    test-DlRrJ
    > Fisnished with exit status 0

# DESCRIPTION

App::RunMatrix runs commands against module version matrix.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
