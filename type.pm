use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::lengthVisitor;

# builds $node->{length}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{symbtab} = $parser->YYData->{symbtab};
	$self->{done_hash} = {};
	$self->{key} = 'c_name';
	return $self;
}

sub _get_defn {
	my $self = shift;
	my ($defn) = @_;
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
	my ($type) = @_;
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

sub visitSpecification {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

#
#	3.7		Module Declaration
#

sub visitModules {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

#
#	3.8		Interface Declaration
#

sub visitBaseInterface {
	my $self = shift;
	my ($node) = @_;
	return if (exists $node->{length});
#	$node->{length} = 'variable';
	# TODO : $self->{done}->{} ???
	$node->{length} = '';		# void* = CORBA_unsigned_long
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

sub visitForwardBaseInterface {
	my $self = shift;
	my ($node) = @_;
	return if (exists $node->{length});
#	$node->{length} = 'variable';
	$node->{length} = '';		# void* = CORBA_unsigned_long
}

#
#	3.9		Value Declaration
#

sub visitStateMember {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	$self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visit($self);
	}
}

#
#	3.10	Constant Declaration
#

sub visitConstant {
}

#
#	3.11	Type Declaration
#

sub visitTypeDeclarator {
	my $self = shift;
	my ($node) = @_;
	my $type = $self->_get_defn($node->{type});
	if (	   $type->isa('TypeDeclarator')
			or $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('EnumType')
			or $type->isa('SequenceType')
			or $type->isa('FixedPtType') ) {
		$type->visit($self);
	}
	$node->{length} = $self->_get_length($type);
}

sub visitNativeType {
	# C mapping is aligned with CORBA 2.1
}

#
#	3.11.1	Basic Types
#

sub visitBasicType {
	# fixed length
}

#
#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitStructType {
	my $self = shift;
	my ($node) = @_;
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
			$type->visit($self);
		}
		$node->{length} ||= $self->_get_length($type);
	}
}

#	3.11.2.2	Discriminated Unions
#

sub visitUnionType {
	my $self = shift;
	my ($node) = @_;
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
			$type->visit($self);
		}
		$node->{length} ||= $self->_get_length($type);
	}
	my $type = $self->_get_defn($node->{type});
	if ($type->isa('EnumType')) {
		$type->visit($self);
	}
}

#	3.11.2.4	Enumerations
#

sub visitEnumType {
	# fixed length
}

#
#	3.11.3	Template Types
#

sub visitSequenceType {
	my $self = shift;
	my ($node) = @_;
	$node->{length} = 'variable';
	my $type = $self->_get_defn($node->{type});
	if (	   $type->isa('TypeDeclarator')
			or $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('SequenceType')
			or $type->isa('StringType')
			or $type->isa('WideStringType')
			or $type->isa('FixedPtType') ) {
		$type->visit($self);
	}
}

sub visitStringType {
	my $self = shift;
	my ($node) = @_;
	$node->{length} = 'variable';
}

sub visitWideStringType {
	my $self = shift;
	my ($node) = @_;
	$node->{length} = 'variable';
}

sub visitFixedPtType {
	# fixed length
}

sub visitFixedPtConstType {
	# fixed length
}

#
#	3.12	Exception Declaration
#

sub visitException {
	my $self = shift;
	my ($node) = @_;
	$node->{length} = undef;
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			my $type = $self->_get_defn($_->{type});
			if (	   $type->isa('TypeDeclarator')
					or $type->isa('StructType')
					or $type->isa('UnionType')
					or $type->isa('SequenceType')
					or $type->isa('FixedPtType') ) {
				$type->visit($self);
			}
			$node->{length} ||= $self->_get_length($type);
		}
	}
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node) = @_;
	my $type = $self->_get_defn($node->{type});
	$type->visit($self);
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visit($self);
	}
}

sub visitVoidType {
	# empty
}

#
#	3.14	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my ($node) = @_;
	$node->{_get}->visit($self);
	$node->{_set}->visit($self) if (exists $node->{_set});
}

#
#	3.15	Repository Identity Related Declarations
#

sub visitTypeId {
	# empty
}

sub visitTypePrefix {
	# empty
}

#
#	3.16	Event Declaration
#

#
#	3.17	Component Declaration
#

sub visitProvides {
	# empty
}

sub visitUses {
	# empty
}

sub visitPublishes {
	# empty
}

sub visitEmits {
	# empty
}

sub visitConsumes {
	# empty
}

#
#	3.18	Home Declaration
#

sub visitFactory {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visit($self);
	}
}

sub visitFinder {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visit($self);
	}
}

##############################################################################

package CORBA::C::typeVisitor;

# builds $node->{c_arg}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
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

sub visitSpecification {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

#
#	3.7		Module Declaration
#

sub visitModules {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

#
#	3.8		Interface Declaration
#

sub visitBaseInterface {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

#
#	3.9		Value Declaration
#

sub visitStateMember {
	# C mapping is aligned with CORBA 2.1
}

sub visitInitializer {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

#
#	3.10	Constant Declaration
#

sub visitConstant {
	# empty
}

#
#	3.11	Type Declaration
#

sub visitTypeDeclarator {
	# empty
}

sub visitNativeType {
	# C mapping is aligned with CORBA 2.1
}

#
#	3.11.2	Constructed Types
#

sub visitStructType {
	# empty
}

sub visitUnionType {
	# empty
}

sub visitEnumType {
	# empty
}

#
#	3.12	Exception Declaration
#

sub visitException {
	# empty
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node) = @_;
	my $type = $self->_get_type($node->{type});
	$node->{c_arg} = CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, '', 'return');
	foreach (@{$node->{list_param}}) {	# parameter
		$type = $self->_get_type($_->{type});
		$_->{c_arg} = CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

#
#	3.14	Attribute Declaration
#

sub visitAttribute {
	my $self = shift;
	my ($node) = @_;
	$node->{_get}->visit($self);
	$node->{_set}->visit($self) if (exists $node->{_set});
}

#
#	3.15	Repository Identity Related Declarations
#

sub visitTypeId {
	# empty
}

sub visitTypePrefix {
	# empty
}

#
#	3.16	Event Declaration
#

#
#	3.17	Component Declaration
#

sub visitProvides {
	# empty
}

sub visitUses {
	# empty
}

sub visitPublishes {
	# empty
}

sub visitEmits {
	# empty
}

sub visitConsumes {
	# empty
}

#
#	3.18	Home Declaration
#

sub visitFactory {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

sub visitFinder {
	# C mapping is aligned with CORBA 2.1
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{c_arg} = CORBA::C::nameattr->NameAttr($self->{symbtab}, $type, $_->{c_name}, $_->{attr});
	}
}

##############################################################################

package CORBA::C::nameattr;

#
#	See	1.21	Summary of Argument/Result Passing
#

# needs $node->{c_name} and $node->{length}

sub NameAttr {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $class = ref $node;
	$class = "BasicType" if ($node->isa("BasicType"));
	$class = "AnyType" if ($node->isa("AnyType"));
	$class = "BaseInterface" if ($node->isa("BaseInterface"));
	$class = "ForwardBaseInterface" if ($node->isa("ForwardBaseInterface"));
	my $func = 'NameAttr' . $class;
	if($proto->can($func)) {
		return $proto->$func($symbtab, $node, $v_name, $attr);
	} else {
		warn "Please implement a function '$func' in '",__PACKAGE__,"'.\n";
	}
}

sub NameAttrBaseInterface {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameAttrBaseInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrForwardBaseInterface {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameAttrBaseInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrTypeDeclarator {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
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
			my $type = $node->{type};
		unless (ref $type) {
			$type = $symbtab->Lookup($type);
		}
		return $proto->NameAttr($symbtab, $type, $v_name, $attr);
	}
}

sub NameAttrNativeType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameAttrNativeType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrBasicType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
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
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if ($attr ne 'return') {
		warn __PACKAGE__,"::NameAttrVoidType : ERROR_INTERNAL \n";
	}
	return $t_name;
}

1;

