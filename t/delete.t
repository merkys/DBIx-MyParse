# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MyParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 25;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

#
# error tests
#

my $single_delete = $parser->parse("
	DELETE LOW_PRIORITY QUICK IGNORE
	FROM database_name.table_name
	WHERE 1
	ORDER BY column_name
	LIMIT 1234
	");

ok(ref($single_delete) eq 'DBIx::MyParse::Query', 'single_delete1');
ok($single_delete->getCommand eq 'SQLCOM_DELETE', 'single_delete2');

my $options = $single_delete->getOptions();

ok(ref($options) eq 'ARRAY', 'single_delete3');

ok((grep {  /OPTION_QUICK/ } @{$options}), 'single_delete4');
ok((grep {  /IGNORE/ } @{$options}), 'single_delete5');
ok((grep {  /TL_WRITE_DELAYED/ } @{$options}), 'single_delete6');

my $tables = $single_delete->getTables();

ok(ref($tables) eq 'ARRAY', 'single_delete7');

my $table = $tables->[0];

ok(ref($table) eq 'DBIx::MyParse::Item', 'single_delete8');
ok($table->getType() eq 'TABLE_ITEM', 'single_delete9');
ok($table->getDatabaseName() eq 'database_name', 'single_delete10');
ok($table->getTableName() eq 'table_name', 'single_delete11');

my $where = $single_delete->getWhere();

ok(ref($where) eq 'DBIx::MyParse::Item', 'single_delete12');

my $orders = $single_delete->getOrder();
ok(ref($orders) eq 'ARRAY', 'single_delete13');

my $order = $orders->[0];
ok(ref($order) eq 'DBIx::MyParse::Item', 'single_delete13');
ok($order->getType() eq 'FIELD_ITEM', 'single_delete14');
ok($order->getFieldName() eq 'column_name', 'single_delete15');

my $limits = $single_delete->getLimit();
my $limit = $limits->[0];
ok($limit eq '1234', 'single_delete16');


#
# Multiple-table delete
#


my $multiple_delete = $parser->parse("
	DELETE table1, table2.*
	FROM table1, table2, table3
	WHERE table1.id = table2.id
	AND table2.id = table3.id;
");

ok(ref($multiple_delete) eq 'DBIx::MyParse::Query', 'multiple_delete1');
ok($multiple_delete->getCommand() eq 'SQLCOM_DELETE_MULTI' , 'multiple_delete2');

my $ref_tables = $multiple_delete->getTables();
my $delete_tables = $multiple_delete->getDeleteTables();
ok(scalar(@{$ref_tables}) == 3, 'multiple_delete3');
ok(scalar(@{$delete_tables}) == 2, 'multiple_delete4');


