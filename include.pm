use strict;
use UNIVERSAL;
use POSIX qw(ctime);

#
#			Interface Definition Language (OMG IDL CORBA v2.4)
#
#			C Language Mapping Specification, New Edition June 1999
#

package CincludeVisitor;

# needs $node->{repos_id} (repositoryIdVisitor), $node->{c_name} (CnameVisitor)
# $node->{c_arg} (CtypeVisitor) and $node->{c_literal} (CliteralVisitor)

use vars qw($VERSION);
$VERSION = '1.0';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser,$incpath) = @_;
	$self->{incpath} = $incpath || '';
	$self->{prefix} = '';				# provision for incskel
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{srcname_size} = $parser->YYData->{srcname_size};
	$self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
	$self->{inc} = {};
	my $filename = $self->{srcname};
	$filename =~ s/^([^\/]+\/)+//;
	$filename =~ s/\.idl$//i;
	$filename .= '.h';
	$self->open_stream($filename);
	$self->{filename} = $filename;
	$self->{done_hash} = {};
	return $self;
}

sub open_stream {
	my $self = shift;
	my($filename) = @_;
	open(OUT, "> $filename")
			or die "can't open $filename ($!).\n";
	$self->{out} = \*OUT;
}

sub _insert_inc {
	my $self = shift;
	my($filename) = @_;
	my $FH = $self->{out};
	if (! exists $self->{inc}->{$filename}) {
		$self->{inc}->{$filename} = 1;
		$filename =~ s/^([^\/]+\/)+//;
		$filename =~ s/\.idl$//i;
		$filename .= '.h';
		print $FH "#include \"",$self->{prefix},$filename,"\"\n";
	}
}

#
#	3.5		OMG IDL Specification
#

sub visitSpecification {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH "/* This file is generated. DO NOT modify it */\n";
	print $FH "// From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
	print $FH "// Generation date : ",POSIX::ctime(time());
	print $FH "\n";
	print $FH "#include <",$self->{incpath},"corba.h>\n";
#	print $FH "#include \"corba.h\"\n";
	print $FH "\n";
	foreach (@{$node->{list_decl}}) {
		$_->visit($self);
	}
	print $FH "\n";
	print $FH "/* End Of File : ",$self->{filename}," */\n";
	close $FH;
}

#
#	3.6		Module Declaration
#

sub visitModule {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "#ifndef _",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "#define _",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "/*\n";
		print $FH " * begin of module ",$node->{idf},"\n";
		print $FH " */\n";
		foreach (@{$node->{list_decl}}) {
			$_->visit($self);
		}
		print $FH "/*\n";
		print $FH " * end of module ",$node->{c_name},"\n";
		print $FH " */\n";
		print $FH "#endif\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.7		Interface Declaration
#
#	See 1.3		Mapping for Interfaces
#

sub visitInterface {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	$self->{itf} = $node->{c_name};
	if ($self->{srcname} eq $node->{filename}) {
#		return if (exists $node->{modifier});	# abstract or local
		print $FH "#ifndef _",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "#define _",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "/*\n";
		print $FH " * begin of interface ",$node->{c_name},"\n";
		print $FH " */\n";
		print $FH "typedef CORBA_Object ",$node->{c_name},";\n";
		print $FH "\n";
		foreach (@{$node->{list_decl}}) {
			if (	   $_->isa('Operation')
					or $_->isa('Attributes') ) {
				next;
			}
			$_->visit($self);
		}
		print $FH "#endif\n";
		print $FH "\n";
		return if (exists $node->{modifier});	# abstract or local
		print $FH "#ifndef _proto_",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "#define _proto_",$self->{prefix},$node->{c_name},"_defined\n";
		print $FH "\n";
		if (keys %{$node->{hash_attribute_operation}}) {
			print $FH "\t\t/*-- prototypes --*/\n";
			print $FH "\n";
			foreach (values %{$node->{hash_attribute_operation}}) {
				next if ($_->isa("Attribute"));
				$_->visit($self);
			}
			print $FH "/*\n";
		}
		print $FH " * end of interface ",$node->{c_name},"\n";
		print $FH " */\n";
		print $FH "#endif\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitForwardInterface {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		if (! exists $node->{modifier}) {		# abstract or local
			print $FH "\n";
			print $FH "typedef ",$node->{c_name},";\n";
			print $FH "\n";
		}
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.8		Value Declaration
#
#	3.8.1	Regular Value Type
#

sub visitRegularValue {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* regular value ",$node->{c_name}," */\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.8.2	Boxed Value Type
#

sub visitBoxedValue {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* boxed value ",$node->{c_name}," */\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.8.3	Abstract Value Type
#

sub visitAbstractValue {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* abstract value ",$node->{c_name}," */\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.8.4	Value Forward Declaration
#

sub visitForwardRegularValue {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* forward regular value ",$node->{c_name}," */\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitForwardAbstractValue {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* forward abstract value ",$node->{c_name}," */\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.9		Constant Declaration
#
#	See	1.6		Mapping for Constants
#

sub visitConstant {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "#define ",$node->{c_name},"\t";
			$node->{value}->visit($self);	# expression
			print $FH "\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitExpression {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH $node->{c_literal};
}

#
#	3.10	Type Declaration
#

sub visitTypeDeclarators {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_value}}) {
		$_->visit($self);
	}
}

sub visitTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{modifier});	# native IDL2.2
	if (	   $node->{type}->isa('StructType')
			or $node->{type}->isa('UnionType')
			or $node->{type}->isa('EnumType')
			or $node->{type}->isa('SequenceType')
			or $node->{type}->isa('StringType')
			or $node->{type}->isa('WideStringType')
			or $node->{type}->isa('FixedPtType') ) {
		$node->{type}->visit($self);
	}
	if ($self->{srcname} eq $node->{filename}) {
		my $FH = $self->{out};
		if (exists $node->{array_size}) {
			#
			#	See	1.15	Mapping for Array
			#
			warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
					unless (@{$node->{array_size}});
			print $FH "typedef ",
					$node->{type}->{c_name},
					" ",$node->{c_name};
			foreach (@{$node->{array_size}}) {
				print $FH "[";
				$_->visit($self);				# expression
				print $FH "]";
			}
			print $FH ";\n";
			my @list = @{$node->{array_size}};
			shift @list;
			print $FH "typedef ",
					$node->{type}->{c_name},
					" ",$node->{c_name},"_slice";
			foreach (@list) {
				print $FH "[";
				$_->visit($self);				# expression
				print $FH "]";
			}
			print $FH ";\n";
			if (defined $node->{type}->{length}) {
				if (exists $self->{use_define}) {
					print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name},"_slice *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"_slice))\n";
				} else {
					print $FH "extern ",$node->{c_name},"_slice * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
				}
			}
		} else {
			print $FH "typedef ",
					$node->{type}->{c_name},
					" ",$node->{c_name},";\n";
		}
	}
}

#
#	3.10.2	Constructed Types
#
#	3.10.2.1	Structures
#
#	See	1.9		Mapping for Structure Types
#

sub visitStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{type}->isa('StructType')
				or $_->{type}->isa('UnionType')
				or $_->{type}->isa('SequenceType')
				or $_->{type}->isa('StringType')
				or $_->{type}->isa('WideStringType')
				or $_->{type}->isa('FixedPtType') ) {
			$_->{type}->visit($self);
		}
	}
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "typedef struct {\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);				# members
		}
		print $FH "} ",$node->{c_name},";\n";
		if (defined $node->{length}) {
			if (exists $self->{use_define}) {
				print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n"
			} else {
				print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
			}
		}
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitMembers {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH "\t",$node->{type}->{c_name};
	my $first = 1;
	foreach (@{$node->{list_value}}) {
		if ($first) {
			$first = 0;
		} else {
			print $FH ",";
		}
		$_->visit($self);				# single or array
	}
	print $FH ";\n";
}

sub visitArray {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH " ",$node->{c_name};
	foreach (@{$node->{array_size}}) {
		print $FH "[";
		$_->visit($self);				# expression
		print $FH "]";
	}
}

sub visitSingle {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH " ",$node->{c_name};
}

#	3.10.2.2	Discriminated Unions
#
#	See	1.10	Mapping for Union Types
#

sub visitUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	foreach (@{$node->{list_expr}}) {
		if (	   $_->{element}->{type}->isa('StructType')
				or $_->{element}->{type}->isa('UnionType')
				or $_->{element}->{type}->isa('SequenceType')
				or $_->{element}->{type}->isa('StringType')
				or $_->{element}->{type}->isa('WideStringType')
				or $_->{element}->{type}->isa('FixedPtType') ) {
			$_->{element}->{type}->visit($self);
		}
	}
	if ($node->{type}->isa('EnumType')) {
		$node->{type}->visit($self);
	}
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "typedef struct {\n";
		print $FH "\t",$node->{type}->{c_name}," _d; // discriminator\n";
		print $FH "\tunion {\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);				# case
		}
		print $FH "\t} _u;\n";
		print $FH "} ",$node->{c_name},";\n";
		if (defined $node->{type}->{length}) {
			if (exists $self->{use_define}) {
				print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n"
			} else {
				print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
			}
		}
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitCase {
	my $self = shift;
	my($node) = @_;
	$node->{element}->visit($self);
}

sub visitElement {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH "\t\t",$node->{type}->{c_name};
		$node->{value}->visit($self);		# array or single
		print $FH ";\n";
}

#	3.10.2.3	Enumerations
#

sub visitEnumType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* enum ",$node->{idf}," */\n";
		foreach (@{$node->{list_expr}}) {
			$_->visit($self);				# enum
		}
		print $FH "\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitEnum {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH "#define ",$node->{c_name},"\t",$node->{c_literal},"\n";
}

#
#	3.10.3	Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "typedef $node->{c_name};\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

sub visitForwardUnionType {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "typedef $node->{c_name};\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.10.4	Template Types
#
#	See	1.11	Mapping for Sequence Types
#

sub visitSequenceType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		if (	   $node->{type}->isa('SequenceType')
				or $node->{type}->isa('StringType')
				or $node->{type}->isa('WideStringType')
				or $node->{type}->isa('FixedPtType') ) {
			$node->{type}->visit($self);
		}
		print $FH "#ifndef _",$node->{c_name},"_defined\n";
		print $FH "#define _",$node->{c_name},"_defined\n";
		print $FH "typedef struct {\n";
		print $FH "\tCORBA_unsigned_long _maximum;\n";
		print $FH "\tCORBA_unsigned_long _length;\n";
		print $FH "\t",$node->{type}->{c_name}," * _buffer;\n";
		print $FH "} ",$node->{c_name},";\n";
		if (exists $self->{use_define}) {
			print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n";
			print $FH "#define ",$node->{c_name},"__allocbuf(len)\t(",$node->{type}->{c_name}," *)CORBA_alloc((len) * sizeof(",$node->{type}->{c_name},"))\n";
		} else {
			print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
			print $FH "extern ",$node->{type}->{c_name}," * ",$node->{c_name},"__allocbuf(CORBA_unsigned_long len);\n";
		}
		print $FH "#endif\n";
	}
}

#
#	See	1.12	Mapping for Strings
#

sub visitStringType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	my $FH = $self->{out};
	print $FH "#ifndef _",$node->{c_name},"_defined\n";
	print $FH "#define _",$node->{c_name},"_defined\n";
	print $FH "typedef CORBA_char * ",$node->{c_name},";\n";
	print $FH "#endif\n";
}

#
#	See	1.13	Mapping for Wide Strings
#

sub visitWideStringType {
	my $self = shift;
	my($node) = @_;
	return if (exists $self->{done_hash}->{$node->{c_name}});
	$self->{done_hash}->{$node->{c_name}} = 1;
	my $FH = $self->{out};
	print $FH "#ifndef _",$node->{c_name},"_defined\n";
	print $FH "#define _",$node->{c_name},"_defined\n";
	print $FH "typedef CORBA_wchar * ",$node->{c_name},";\n";
	print $FH "#endif\n";
}

#
#	See	1.14	Mapping for Fixed
#

sub visitFixedPtType {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		if (exists $node->{d}) {
			print $FH "#ifndef _",$node->{c_name},"_defined\n";
			print $FH "#define _",$node->{c_name},"_defined\n";
			print $FH "typedef struct {\n";
			print $FH "\tCORBA_unsigned_short _digits;\n";
			print $FH "\tCORBA_short _scale;\n";
			print $FH "\tCORBA_char _value [(",
					$node->{d}->{value}, "+",
					$node->{s}->{value}, ")/2];\n";
			print $FH "} ",$node->{c_name},";\n";
			# alloc : TODO
			print $FH "#endif\n";
		}
	}
}

#
#	3.11	Exception Declaration
#
#	See	1.16	Mapping for Exception Types
#

sub visitException {
	my $self = shift;
	my($node) = @_;
	if (exists $node->{list_expr}) {
		warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
				unless (@{$node->{list_expr}});
		foreach (@{$node->{list_expr}}) {
			if (	   $_->{type}->isa('StructType')
					or $_->{type}->isa('UnionType')
					or $_->{type}->isa('SequenceType')
					or $_->{type}->isa('StringType')
					or $_->{type}->isa('WideStringType')
					or $_->{type}->isa('FixedPtType') ) {
				$_->{type}->visit($self);
			}
		}
	}
	my $FH = $self->{out};
	if ($self->{srcname} eq $node->{filename}) {
		print $FH "/* exception ",$node->{idf}," */\n";
		print $FH "typedef struct ",$node->{c_name}," {\n";
		if (exists $node->{list_expr}) {
			foreach (@{$node->{list_expr}}) {
				$_->visit($self);				# members
			}
		} else {
			print $FH "\tCORBA_long _dummy;\n";
		}
		print $FH "} ",$node->{c_name},";\n";
		print $FH "#define ex_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
		if (exists $self->{use_define}) {
			print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n";
		} else {
			print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
		}
		print $FH "\n";
	} else {
		$self->_insert_inc($node->{filename});
	}
}

#
#	3.12	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_param}}) {
		if (	   $_->{type}->isa('StringType')
				or $_->{type}->isa('WideStringType') ) {
			$_->{type}->visit($self);
		}
	}
	my $FH = $self->{out};
	print $FH "extern ",$node->{c_arg}," ",$self->{prefix},$node->{c_name},"(\n";
	print $FH "\t",$self->{itf}," _o,\n";
	foreach (@{$node->{list_param}}) {
		$_->visit($self);				# parameter
	}
	print $FH "\tCORBA_Context _ctx,\n"
			if (exists $node->{list_context});
	print $FH "\tCORBA_Environment * _ev\n";
	print $FH ");\n";
}

sub visitParameter {
	my $self = shift;
	my($node) = @_;
	my $FH = $self->{out};
	print $FH "\t",$node->{c_arg},", // ",$node->{attr};
		print $FH " (variable length)\n" if (defined $node->{type}->{length});
		print $FH " (fixed length)\n" unless (defined $node->{type}->{length});
}

##############################################################################

package CincskelVisitor;

@CincskelVisitor::ISA = qw(CincludeVisitor);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser,$incpath,$prefix) = @_;
	$self->{incpath} = $incpath || '';
	$prefix = "skel_" unless (defined $prefix);
	$self->{prefix} = $prefix;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{srcname_size} = $parser->YYData->{srcname_size};
	$self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
	$self->{inc} = {};
	$self->{use_define} = 1;
	my $filename = $self->{srcname};
	$filename =~ s/^([^\/]+\/)+//;
	$filename =~ s/\.idl$//i;
	$filename = $prefix . $filename . '.h';
	$self->open_stream($filename);
	$self->{filename} = $filename;
	$self->{done_hash} = {};
	return $self;
}

1;

