use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C Language Mapping Specification, New Edition June 1999
#

package ClengthVisitor;

# builds $node->{length}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{symbtab} = $parser->YYData->{symbtab};
	$self->{done_hash} = {};
	$self->{key} = 'c_name';
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

#	See	1.8		Mapping Considerations for Constructed Types
#

sub _get_length {
	my $self = shift;
	my($type) = @_;
	if (	   $type->isa('AnyType')
			or $type->isa('SequenceType')
			or $type->isa('StringType')
			or $type->isa('WideStringType')
			or $type->isa('ObjectType') ) {
		return 'variable';
	}
	if (	   $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('TypeDeclarator') ) {
		return $type->{length};
	}
	return undef;
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
	return if (exists $node->{length});
#	$node->{length} = 'variable';
	# TODO : $self->{done}->{} ???
	$node->{length} = '';		# void* = CORBA_unsigned_long
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
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameInitializer {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visitName($self);
	}
}

#
#	3.10	Constant Declaration
#

sub visitNameConstant {
}

#
#	3.11	Type Declaration
#

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{modifier});	# native IDL2.2
	my $type = $self->_get_defn($node->{type});
	if (	   $type->isa('TypeDeclarator')
			or $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('EnumType')
			or $type->isa('SequenceType')
			or $type->isa('FixedPtType') ) {
		$type->visitName($self);
	}
	$node->{length} = $self->_get_length($type);
}

#
#	3.11.1	Basic Types
#

sub visitNameBasicType {
	# fixed length
}

#
#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{$self->{key}}});
	$self->{done_hash}->{$node->{$self->{key}}} = 1;
	$node->{length} = undef;
	foreach (@{$node->{list_expr}}) {
		my $type = $self->_get_defn($_->{type});
		if (	   $type->isa('TypeDeclarator')
				or $type->isa('StructType')
				or $type->isa('UnionType')
				or $type->isa('SequenceType')
				or $type->isa('StringType')
				or $type->isa('WideStringType')
				or $type->isa('FixedPtType') ) {
			$type->visitName($self);
		}
		$node->{length} ||= $self->_get_length($type);
	}
}

#	3.11.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{$self->{key}}});
	$self->{done_hash}->{$node->{$self->{key}}} = 1;
	$node->{length} = undef;
	foreach (@{$node->{list_expr}}) {
		my $type = $self->_get_defn($_->{element}->{type});
		if (	   $type->isa('TypeDeclarator')
				or $type->isa('StructType')
				or $type->isa('UnionType')
				or $type->isa('SequenceType')
				or $type->isa('StringType')
				or $type->isa('WideStringType')
				or $type->isa('FixedPtType') ) {
			$type->visitName($self);
		}
		$node->{length} ||= $self->_get_length($type);
	}
	my $type = $self->_get_defn($node->{type});
	if ($type->isa('EnumType')) {
		$type->visitName($self);
	}
}

#	3.11.2.4	Enumerations
#

sub visitNameEnumType {
	# fixed length
}

#
#	3.11.3	Template Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node) = @_;
	$node->{length} = 'variable';
	my $type = $self->_get_defn($node->{type});
	if (	   $type->isa('TypeDeclarator')
			or $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('SequenceType')
			or $type->isa('StringType')
			or $type->isa('WideStringType')
			or $type->isa('FixedPtType') ) {
		$type->visitName($self);
	}
}

sub visitNameStringType {
	my $self = shift;
	my($node) = @_;
	$node->{length} = 'variable';
}

sub visitNameWideStringType {
	my $self = shift;
	my($node) = @_;
	$node->{length} = 'variable';
}

sub visitNameFixedPtType {
	# fixed length
}

sub visitNameFixedPtConstType {
	# fixed length
}

#
#	3.12	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$node->{length} = undef;
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitNameException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			my $type = $self->_get_defn($_->{type});
			if (	   $type->isa('TypeDeclarator')
					or $type->isa('StructType')
					or $type->isa('UnionType')
					or $type->isa('SequenceType')
					or $type->isa('FixedPtType') ) {
				$type->visitName($self);
			}
			$node->{length} ||= $self->_get_length($type);
		}
	}
}

#
#	3.13	Operation Declaration
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	my $type = $self->_get_defn($node->{type});
	$type->visitName($self);
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visitName($self);
	}
}

sub visitNameVoidType {
	# empty
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
	# empty
}

sub visitNameUses {
	# empty
}

sub visitNamePublishes {
	# empty
}

sub visitNameEmits {
	# empty
}

sub visitNameConsumes {
	# empty
}

#
#	3.18	Home Declaration
#

sub visitNameFactory {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visitName($self);
	}
}

sub visitNameFinder {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visitName($self);
	}
}

##############################################################################

package CtypeVisitor;

# builds $node->{c_arg}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

sub _get_type {
	my $self = shift;
	my ($type) = @_;

	if (ref $type) {
		return $type;
	} else {
		$self->{symbtab}->Lookup($type);
	}
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
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.9		Value Declaration
#

sub visitNameStateMember {
	# C mapping is aligned with CORBA 2.1
}

sub visitNameInitializer {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = Cnameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

#
#	3.10	Constant Declaration
#

sub visitNameConstant {
	# empty
}

#
#	3.11	Type Declaration
#

sub visitNameTypeDeclarator {
	# empty
}

#
#	3.11.2	Constructed Types
#

sub visitNameStructType {
	# empty
}

sub visitNameUnionType {
	# empty
}

sub visitNameEnumType {
	# empty
}

#
#	3.12	Exception Declaration
#

sub visitNameException {
	# empty
}

#
#	3.13	Operation Declaration
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	my $type = $self->_get_type($node->{type});
	$node->{c_arg} = Cnameattr->NameAttr($self->{symbtab}, $type, '', 'return');
	foreach (@{$node->{list_param}}) {	# parameter
		$type = $self->_get_type($_->{type});
		$_->{c_arg} = Cnameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
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
	# empty
}

sub visitNameUses {
	# empty
}

sub visitNamePublishes {
	# empty
}

sub visitNameEmits {
	# empty
}

sub visitNameConsumes {
	# empty
}

#
#	3.18	Home Declaration
#

sub visitNameFactory {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = Cnameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

sub visitNameFinder {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = Cnameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

##############################################################################

package Cnameattr;

#
#	See	1.21	Summary of Argument/Result Passing
#

# needs $node->{c_name} and $node->{length}

sub NameAttr {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $class = ref $node;
	$class = "BasicType" if ($node->isa("BasicType"));
	$class = "AnyType" if ($node->isa("AnyType"));
	my $func = 'NameAttr' . $class;
	if($proto->can($func)) {
		return $proto->$func($symbtab, $node, $v_name, $attr);
	} else {
		warn "Please implement a function '$func' in '",__PACKAGE__,"'.\n";
	}
}

sub NameAttrRegularInterface {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameAttrRegularInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrAbstractInterface {
	# C mapping is aligned with CORBA 2.1
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameAttrAbstractInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrLocalInterface {
	# C mapping is aligned with CORBA 2.1
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameAttrLocalInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrRegularValue {
	# C mapping is aligned with CORBA 2.1
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrBoxedValue {
	# C mapping is aligned with CORBA 2.1
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrAbstractValue {
	# C mapping is aligned with CORBA 2.1
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrTypeDeclarator {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	if (exists $node->{array_size}) {
		my $t_name = $node->{c_name};
		if (      $attr eq 'in' ) {
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'inout' ) {
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'out' ) {
			if (defined $node->{length}) {		# variable
				return $t_name . "_slice ** " . $v_name;
			} else {
				return $t_name . " " . $v_name;
			}
		} elsif ( $attr eq 'return' ) {
			return $t_name . "_slice *";
		} else {
			warn __PACKAGE__,"::NameAttrTypeDeclarator array : ERROR_INTERNAL $attr \n";
		}
	} else {
		if (exists $node->{modifier}) {		# native
			# C mapping is aligned with CORBA 2.1
			my $t_name = $node->{c_name};
			if (      $attr eq 'in' ) {
				return $t_name . " "   . $v_name;
			} elsif ( $attr eq 'inout' ) {
				return $t_name . " * " . $v_name;
			} elsif ( $attr eq 'out' ) {
				return $t_name . " * " . $v_name;
			} elsif ( $attr eq 'return' ) {
				return $t_name;
			} else {
				warn __PACKAGE__,"::NameAttrTypeDeclarator : ERROR_INTERNAL $attr \n";
			}
		} else {
			my $type = $node->{type};
			unless (ref $type) {
				$type = $symbtab->Lookup($type);
			}
			return $proto->NameAttr($symbtab, $type, $v_name, $attr);
		}
	}
}

sub NameAttrBasicType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameAttrBasicType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrAnyType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	$node->{length} = 'variable';
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " ** " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . " *";
	} else {
		warn __PACKAGE__,"::NameAttrAnyType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStructType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " ** " . $v_name;
		} else {
			return $t_name . " * "  . $v_name;
		}
	} elsif ( $attr eq 'return' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " *";
		} else {
			return $t_name;
		}
	} else {
		warn __PACKAGE__,"::NameAttrStructType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrUnionType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " ** " . $v_name;
		} else {
			return $t_name . " * "  . $v_name;
		}
	} elsif ( $attr eq 'return' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " *";
		} else {
			return $t_name;
		}
	} else {
		warn __PACKAGE__,"::NameAttrUnionType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrEnumType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::AttrNameEnumType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrSequenceType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " ** " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . " *";
	} else {
		warn __PACKAGE__,"::AttrNameSequenceType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStringType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::AttrNameStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrWideStringType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::AttrNameWideStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrFixedPtType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameAttrFixedPtType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrVoidType {
	my $proto = shift;
	my($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if ($attr ne 'return') {
		warn __PACKAGE__,"::NameAttrVoidType : ERROR_INTERNAL \n";
	}
	return $t_name;
}

1;

