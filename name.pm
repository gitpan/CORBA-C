use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v2.4)
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
	$self->{srcname} = $parser->YYData->{srcname};
	return $self;
}

#
#	See	1.2		Scoped Names
#
sub _get_name {
	my $self = shift;
	my($node) = @_;
	my $name = $node->{coll};
	$name =~ s/^:://;
	$name =~ s/::/_/g;
	return $name;
}

sub _get_name_fwd {
	my $self = shift;
	my($node) = @_;
	my $name = $node->{fwd}->{coll};
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
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.6		Module Declaration
#

sub visitNameModule {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.7		Interface Declaration
#

sub visitNameInterface {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_decl}}) {
		if (	   $_->isa('Operation')
				or $_->isa('Attributes') ) {
			next;
		}
		$_->visitName($self);
	}
	if ($self->{srcname} eq $node->{filename}) {
		if (keys %{$node->{hash_attribute_operation}}) {
			$self->{itf} = $node->{$self->{key}};
			foreach (values %{$node->{hash_attribute_operation}}) {
				$_->visitName($self);
			}
			delete $self->{itf};
		}
	}
}

sub visitNameForwardInterface {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name_fwd($node);
}

#
#	3.8		Value Declaration
#

sub visitNameRegularValue {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameBoxedValue {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameAbstractValue {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
}

sub visitNameForwardRegularValue {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name_fwd($node);
}

sub visitNameForwardAbstractValue {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name_fwd($node);
}

#
#	3.9		Constant Declaration
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
#	3.10	Type Declaration
#

sub visitNameTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);
	}
}

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	if (exists $node->{modifier}) {		# native IDL2.2
		$node->{$self->{key}} = $node->{idf};
	} else {
		$node->{$self->{key}} = $self->_get_name($node);
		$node->{type}->visitName($self);
	}
}

#
#	3.10.1	Basic Types
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
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);			# single or array
	}
}

sub visitNameArray {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$node->{type}->visitName($self);
}

sub visitNameSingle {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$node->{type}->visitName($self);
}

#	3.10.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	$node->{type}->visitName($self);
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
	$node->{value}->visitName($self);		# array or single
}

#	3.10.2.3	Enumerations
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
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitNameForwardStructType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name_fwd($node);
}

sub visitNameForwardUnionType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name_fwd($node);
}

#
#	3.10.4	Template Types
#
#	See	1.11	Mapping for Sequence Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node) = @_;
	my $type = $node->{type};
	while (		$type->isa('TypeDeclarator')
			and ! exists $type->{array_size} ) {
		$type = $type->{type};
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
	my $name = "CORBA_fixed";
	if (exists $node->{d}) {
		$name .= "_" . $node->{d}->{value} . "_" . $node->{s}->{value};
	}
	$node->{$self->{key}} = $name;
}

#
#	3.11	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->_get_name($node);
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);			# single or array
	}
}

#
#	3.12	Operation Declaration
#
#	See	1.4		Inheritance and Operation Names
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $self->{itf} . '_' . $node->{idf};
	$node->{type}->visitName($self);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

sub visitNameParameter {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = $node->{idf};
	$node->{type}->visitName($self);
}

sub visitNameVoidType {
	my $self = shift;
	my($node) = @_;
	$node->{$self->{key}} = "void";
}

#
#	3.13	Attribute Declaration
#

sub visitNameAttribute {
	# empty
}

##############################################################################

package ClengthVisitor;

# builds $node->{length}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{done_hash} = {};
	return $self;
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
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.6		Module Declaration
#

sub visitNameModule {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self);
	}
}

#
#	3.7		Interface Declaration
#

sub visitNameInterface {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		if (	   $_->isa('Operation')
				or $_->isa('Attributes') ) {
			next;
		}
		$_->visitName($self);				# builds $node->{length}
	}
	if ($self->{srcname} eq $node->{filename}) {
		foreach (values %{$node->{hash_attribute_operation}}) {
			next if ($_->isa("Attribute"));
			$_->visitName($self);			# builds $node->{length}
		}
	}
}

sub visitNameForwardInterface {
	# empty
}

#
#	3.8		Value Declaration
#

sub visitNameRegularValue {
	# empty
}

sub visitNameBoxedValue {
	# empty
}

sub visitNameAbstractValue {
	# empty
}

sub visitNameForwardRegularValue {
	# empty
}

sub visitNameForwardAbstractValue {
	# empty
}

#
#	3.9		Constant Declaration
#

sub visitNameConstant {
}

#
#	3.10	Type Declaration
#

sub visitNameTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visitName($self);
	}
}

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{modifier});	# native IDL2.2
	if (	   $node->{type}->isa('StructType')
			or $node->{type}->isa('UnionType')
			or $node->{type}->isa('EnumType')
			or $node->{type}->isa('SequenceType')
			or $node->{type}->isa('FixedPtType') ) {
		$node->{type}->visitName($self);
	}
	$node->{length} = $self->_get_length($node->{type});
}

#
#	3.10.1	Basic Types
#

sub visitNameBasicType {
	# fixed length
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	$node->{length} = undef;
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{type}->isa('StructType')
				or $_->{type}->isa('UnionType')
				or $_->{type}->isa('SequenceType')
				or $_->{type}->isa('FixedPtType') ) {
			$_->{type}->visitName($self);
		}
		$node->{length} ||= $self->_get_length($_->{type});
	}
}

#	3.10.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	$node->{length} = undef;
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{element}->{type}->isa('StructType')
				or $_->{element}->{type}->isa('UnionType')
				or $_->{element}->{type}->isa('SequenceType')
				or $_->{element}->{type}->isa('FixedPtType') ) {
			$_->{element}->{type}->visitName($self);
		}
		$node->{length} ||= $self->_get_length($_->{element}->{type});
	}
	if ($node->{type}->isa('EnumType')) {
		$node->{type}->visitName($self);
	}
}

#	3.10.2.3	Enumerations
#

sub visitNameEnumType {
	# fixed length
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitNameForwardStructType {
	# empty
}

sub visitNameForwardUnionType {
	# empty
}

#
#	3.10.4	Template Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node) = @_;
	$node->{length} = 'variable';
	if (	   $node->{type}->isa('SequenceType')
			or $node->{type}->isa('FixedPtType') ) {
		$node->{type}->visitName($self);
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

#
#	3.11	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	$node->{length} = undef;
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitNameException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			if (	   $_->{type}->isa('StructType')
					or $_->{type}->isa('UnionType')
					or $_->{type}->isa('SequenceType')
					or $_->{type}->isa('FixedPtType') ) {
				$_->{type}->visitName($self);
			}
			$node->{length} ||= $self->_get_length($_->{type});
		}
	}
}

#
#	3.12	Operation Declaration
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{type}->visitName($self)
			unless ($node->{type}->isa('VoidType'));
	foreach (@{$node->{list_param}}) {
		$_->{type}->visitName($self);
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
	return $self;
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self) if ($_->isa("Interface") or $_->isa("Module"));
	}
}

#
#	3.6		Module Declaration
#

sub visitNameModule {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_decl}}) {
		$_->visitName($self) if ($_->isa("Interface") or $_->isa("Module"));
	}
}

#
#	3.7		Interface Declaration
#

sub visitNameInterface {
	my $self = shift;
	my($node) = @_;
	if ($self->{srcname} eq $node->{filename}) {
		foreach (values %{$node->{hash_attribute_operation}}) {
			next if ($_->isa("Attribute"));
			$_->visitName($self);			# builds $node->{c_arg}
		}
	}
}

#
#	3.12	Operation Declaration
#

sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{c_arg} = Cnameattr->NameAttr($node->{type},'','return');
	foreach (@{$node->{list_param}}) {	# parameter
		$_->{c_arg} = Cnameattr->NameAttr($_->{type},$_->{c_name},$_->{attr});
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
	my($node, $v_name, $attr) = @_;
	my $class = ref $node;
	$class = "BasicType" if ($node->isa("BasicType"));
	$class = "AnyType" if ($node->isa("AnyType"));
	my $func = 'NameAttr' . $class;
	return $proto->$func($node,$v_name,$attr);
}

sub NameAttrInterface {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
	my($node, $v_name, $attr) = @_;
	if (exists $node->{array_size}) {
#		my $t_name = $node->{type}->{c_name};
#		my $array = '';
#		foreach (@{$node->{array_size}}) {
#			$array .= "[" . $_->{c_literal} . "]";
#		}
		my $t_name = $node->{c_name};
		if (      $attr eq 'in' ) {
#			return $t_name . " " . $v_name . $array;
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'inout' ) {
#			return $t_name . " " . $v_name . $array;
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'out' ) {
			if (defined $node->{length}) {		# variable
				return $t_name . "_slice ** " . $v_name;
			} else {
#				return $t_name . " " . $v_name . $array;
				return $t_name . " " . $v_name;
			}
		} elsif ( $attr eq 'return' ) {
			return $t_name . "_slice *";
		} else {
			warn __PACKAGE__,"::NameTypeDeclarator array : ERROR_INTERNAL $attr \n";
		}
	} else {
		return $proto->NameAttr($node->{type},$v_name,$attr);
	}
}

sub NameAttrBasicType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameBasicType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrAnyType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameAnyType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStructType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameStructType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrUnionType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameUnionType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrEnumType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameEnumType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrSequenceType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameSequenceType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStringType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
#	unless (defined $node->{length}) {
#		$node->{length} = 'variable';
#		warn "String without variable length\n";
#	}
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
		warn __PACKAGE__,"::NameStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrWideStringType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
#	unless (defined $node->{length}) {
#		$node->{length} = 'variable';
#		warn "String without variable length\n";
#	}
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
		warn __PACKAGE__,"::NameWideStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrFixedPtType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
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
		warn __PACKAGE__,"::NameFixedPtType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrVoidType {
	my $proto = shift;
	my($node, $v_name, $attr) = @_;
	my $t_name = $node->{c_name};
	if ($attr ne 'return') {
		warn __PACKAGE__,"::NameVoidType : ERROR_INTERNAL \n";
	}
	return $t_name;
}

1;

