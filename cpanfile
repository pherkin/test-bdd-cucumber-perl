
requires 'perl', '5.010';
requires 'File::Find::Rule';
requires 'JSON::MaybeXS', '1.1.0';
# List::Util 1.33 adds 'any'
requires 'List::Util', '1.33';
requires 'Module::Runtime';
requires 'Moo', '2.2.2';
requires 'MooX::HandlesVia';
requires 'Path::Class';
requires 'TAP::Parser::Iterator';
requires 'TAP::Parser::SourceHandler';
requires 'Term::ANSIColor', '3.00';
# Test2::API 1.302087 adds 'pass' and 'fail'
requires 'Test2::API', '1.302087';
requires 'Test2::Tools::Basic';
requires 'Test::More';
requires 'Types::Standard';
# YAML 1.15 fixes the need to have  a newline at the end of the input
#  we used to depend on YAML::Syck which does not have that requirement
requires 'YAML', '1.15';

on 'test' => sub {
    requires 'File::Copy::Recursive';
    requires 'IO::Scalar';
    requires 'Path::Tiny';
    requires 'Test::Differences';
    requires 'Test::Exception';
    requires 'Test::Pod';
};
