use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C Language Mapping Specification, New Edition June 1999
#

package CnameVisitor;

# builds $node->{c_name}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{key} = 'c_name';
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

sub _get_defn {
	my $self = shift;
	my($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{symbtab}->Lookup($defn);
	}
}

#
#	See	1.2		Scoped Names
#
sub _get_name {
	my $self = shift;
	my($node) = @_;
	my $name = $node->{full};
	$name =~ s/^:://;
	$name =~ s/::/_/g;
	return $name;
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.7		Module Declaration
#

sub visitNameModules {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.8		Interface Declaration
#

sub visitNameBaseInterface {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.9		Value Declaration
#

sub visitNameStateMember {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameInitializer {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

#
#	3.10	Constant Declaration
#

sub visitNameConstant {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameExpression {
	# empty
}

#
#	3.11	Type Declaration
#

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	if (exists $node->{modifier}) {		# native IDL2.2
		$node->{$self->{key}} = $node->{idf};
	} else {
		$node->{$self->{key}} = $self->_get_name($node);
		$self->_get_defn($node->{type})->visitName($self);
	}
}

#
#	3.11.1	Basic Types
#
#	See	1.7		Mapping for Basic Data Types
#

sub visitNameBasicType {
	my $self = shift;
	my($node) = @_;
	my $name = $node->{value};
	$name =~ s/ /_/g;
	$node->{$self->{key}} = "CORBA_" . $name;
}

#
#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_value}}) {
		$self->_get_defn($_)->visitName($self);		# single or array
	}
}

sub visitNameArray {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameSingle {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$self->_get_defn($node->{type})->visitName($self);
}

#	3.11.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);			# case
	}
}

sub visitNameCase {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_label}}) {
		$_->visitName($self);			# default or expression
	}
	$node->{element}->visitName($self);
}

sub visitNameDefault {
	# empty
}

sub visitNameElement {
	my $self = shift;
	my($node) = @_;
	$self->_get_defn($node->{value})->visitName($self);		# single or array
}

#	3.11.2.4	Enumerations
#

sub visitNameEnumType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = "CORBA_long";
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);			# enum
	}
}

sub visitNameEnum {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
}

#
#	3.11.3	Template Types
#
#	See	1.11	Mapping for Sequence Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node) = @_;
	my $type = $self->_get_defn($node->{type});
	while (		$type->isa('TypeDeclarator')
			and ! exists $type->{array_size} ) {
		$type = $self->_get_defn($type->{type});
	}
	$type->visitName($self);
	my $name = $type->{$self->{key}};
	$name =~ s/^CORBA_//;
	$node->{$self->{key}} = "CORBA_sequence_" . $name;
}

#
#	See	1.12	Mapping for Strings
#

sub visitNameStringType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = "CORBA_string";
}

#
#	See	1.13	Mapping for Wide Strings
#

sub visitNameWideStringType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = "CORBA_wstring";
}

#
#	See	1.14	Mapping for Fixed
#

sub visitNameFixedPtType {
	my $self = shift;
	my($node) = @_;
	my $name = "CORBA_fixed_" . $node->{d}->{value} . "_" . $node->{s}->{value};
	$node->{$self->{key}} = $name;
}

sub visitNameFixedPtConstType {
	my $self = shift;
	my($node) = @_;
	my $name = "CORBA_fixed";
	$node->{$self->{key}} = $name;
}

#
#	3.12	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_value}}) {
		$self->_get_defn($_)->visitName($self);		# single or array
	}
}

#
#	3.13	Operation Declaration
#
#	See	1.4		Inheritance and Operation Names
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$self->_get_defn($node->{type})->visitName($self);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

sub visitNameParameter {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameVoidType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = "void";
}

#
#	3.14	Attribute Declaration
#

sub visitNameAttribute {
	my $self = shift;
	my($node) = @_;
	$node->{_get}->visitName($self);
	$node->{_set}->visitName($self) if (exists $node->{_set});
}

#
#	3.15	Repository Identity Related Declarations
#

sub visitNameTypeId {
	# empty
}

sub visitNameTypePrefix {
	# empty
}

#
#	3.16	Event Declaration
#

#
#	3.17	Component Declaration
#

sub visitNameProvides {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameUses {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNamePublishes {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameEmits {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameConsumes {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{$self->{key}});
	$node->{$self->{key}} = $self->_get_name($node);
}

#
#	3.18	Home Declaration
#

sub visitNameFactory {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

sub visitNameFinder {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

1;

