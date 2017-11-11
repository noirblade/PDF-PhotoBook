package PhotoAlbums::PhotoAlbums::Utils::Image;
use Image::Magick;
use PDF::Reuse;
use strict;

sub new {
	my ($class, $args) = @_;
	my $self = {};

	bless($self, $class);
	
	$self->{'registry'} = PhotoAlbums::PFrame1_2::Registry->instance();
	$self->{'config'} = $self->{'registry'}->{'store'}->{'config'} if !$self->{'config'};
	return $self;
}

sub createMain{
	my ($self, $args) = @_;
	#my ($self, $template) = @_;

	#print STDERR "\033[34mCreate main " . $template . "\033[0m\n";
	print STDERR "\033[34mCreate main \033[0m\n";
	$self->{'template'} = Image::Magick->new();
	#$self->{'template'}->ReadImage( "png:" . $template);
	# Set correct size
	$self->{'template'}->Set('size' => $self->{'width'} . 'x' . $self->{'height'});
	$self->{'template'}->ReadImage( "xc: white");
	return 1;
}

sub setSizes{
	my ($self, $width, $height) = @_;
	
	$self->{'width'}  = $width;
	$self->{'height'} = $height;

	return 1;
}

sub checkImageFormat{
	my ($self, $args) = @_;
	
	$self->{'userImage'} = Image::Magick->new();
	my ($width, $height, $size, $format) = $self->{'userImage'}->Ping($args->{'userImage'});
	
	if (!$format){
		return 0;
	}
	$self->{'userImageType'} = $format;
	return 1;
}

sub applyMask{
	my ($self, $args) = @_;

	# Done above
	#$self->{'userImage'} = Image::Magick->new() if !$self->{'userImage'};

	print STDERR "IMAGE FORMAT: " . $self->{'userImageType'} . "\n";
	print STDERR $self->{'userImage'}->ReadImage( $self->{'userImageType'} . ":" . $args->{'userImage'});
	$self->{'userImage'}->Set( alpha => 'set');
	
	# Rotate image
	if ($args->{'degrees'} && $args->{'degrees'} > 0){
		print STDERR "Rotating to: " . $args->{'degrees'} . " degrees \n";
		$self->{'userImage'}->Rotate(degrees => $args->{'degrees'}, background => 'none');
	}

	# Zoom, Crop etc...
	$self->{'userImage'}->Resize(geometry => $args->{'imageWidth'} . 'x' . $args->{'imageHeight'});

	#$args->{'imageX'} = '+' . $args->{'imageX'} if $args->{'imageX'} >= 0;
	#$args->{'imageY'} = '+' . $args->{'imageY'} if $args->{'imageY'} >= 0;

	$args->{'imageX'} = $args->{'imageX'} * -1;
	$args->{'imageY'} = $args->{'imageY'} * -1;
	print STDERR $args->{'imageWidth'} . 'x' . $args->{'imageHeight'} . ' X = ' . $args->{'imageX'} . ' Y = ' . $args->{'imageY'} . "\n";
	#my $err = $self->{'framed'}->Crop($args->{'placeWidth'} . 'x' . $args->{'placeHeight'} . $args->{'imageX'}  . $args->{'imageY'});
	my $err = $self->{'userImage'}->Crop('width'  => $args->{'placeWidth'},
					  'height' => $args->{'placeHeight'},
					  'x'      => $args->{'imageX'},
					  'y'      => $args->{'imageY'},
				  );
	warn $err if $err;
	
	# Flop image
	if ($args->{'flop'}){
		$self->{'userImage'}->Flop();
	}
	if ($args->{'mask'}){
		$self->{'mask'} = Image::Magick->new();
		$self->{'mask'}->ReadImage( "png:" . $args->{'mask'});
		$self->{'mask'}->Resize(width => $args->{'placeWidth'}, height => $args->{'placeHeight'});
	
		$self->{'userImage'}->Composite( image => $self->{'mask'},
		                  compose => 'DstIn',
		                  gravity => 'Center',
		                  quality => 100,
		                );
		push (@{$self->{'garbage'}}, $self->{'mask'});
		#$self->{'userImage'}->Write("png:masked.png");
	} 
	push (@{$self->{'garbage'}}, $self->{'userImage'});
	return 1;
}

sub applyFrame{
	my ($self, $args) = @_;
	
	print STDERR "   Appling frame \n";
	if ($args->{'frame'}){
		$self->{'framed'} = Image::Magick->new();
		$self->{'framed'}->ReadImage( "png:" . $args->{'frame'});

		#$self->{'framed'}->Resize(geometry => $args->{'placeWidth'} . 'x' . $args->{'placeHeight'});
		$self->{'framed'}->Resize(width => $args->{'placeWidth'}, height => $args->{'placeHeight'});

		$self->{'userImage'}->Composite( image => $self->{'framed'},
		                  compose => 'over',
		                  gravity => 'Center',
		                  quality => 100,
		                );
		push (@{$self->{'garbage'}}, $self->{'framed'});
	} 
	#$self->{'framed'}->Write("png:framed.pdf");
	return 1;
}


sub paint{
	my ($self, $args) = @_;

	print STDERR "   Painting \n";

	# Parametrize this!!!
#	$self->{'userImage'}->Rotate(degrees => 0, background => 'none');
#
#	# Zoom, Crop etc...
#	$self->{'userImage'}->Resize(geometry => $args->{'imageWidth'} . 'x' . $args->{'imageHeight'});
#	
	#$args->{'imageX'} = '+' . $args->{'imageX'} if $args->{'imageX'} >= 0;
	#$args->{'imageY'} = '+' . $args->{'imageY'} if $args->{'imageY'} >= 0;

#	$args->{'imageX'} = $args->{'imageX'} * -1;
#	$args->{'imageY'} = $args->{'imageY'} * -1;
#	print STDERR $args->{'imageWidth'} . 'x' . $args->{'imageHeight'} . ' X = ' . $args->{'imageX'} . ' Y = ' . $args->{'imageY'} . "\n";
	#my $err = $self->{'userImage'}->Crop($args->{'placeWidth'} . 'x' . $args->{'placeHeight'} . $args->{'imageX'}  . $args->{'imageY'});
#	my $err = $self->{'userImage'}->Crop('width'  => $args->{'placeWidth'},
#					  'height' => $args->{'placeHeight'},
#					  'x'      => $args->{'imageX'},
#					  'y'      => $args->{'imageY'},
#				  );
#	warn $err if $err;
	# TODO Parametrize this
	#$self->{'userImage'}->Flop();
	print STDERR $self->{'template'}->Composite(
					image => $self->{'userImage'},
					compose => 'Over',
					#rotate  => 20,
					gravity => 'NorthWest',
					geometry=> '+' . $args->{'placeX'} . '+' . $args->{'placeY'},
					#geometry=>'10x10',
					#quality => 100,
					);
	return 1;
}

sub createLayoutPdf{
	my ($self, $layputPdf) = @_;

	$self->{'pdf'} = Image::Magick->new();
	# Set correct size
	$self->{'pdf'}->Set('size' => $self->{'width'} . 'x' . $self->{'height'});
	$self->{'pdf'}->ReadImage( "xc: white");

	$self->{'pdf'}->Composite( image => $self->{'template'},
	                 compose => 'Over',
       		         #mask    => $main,
       		         x => 0,
       		         y => 0,
               		 gravity => 'East',
               		 quality => 100,
        );

	$self->{'pdf'}->Write("pdf:" . $layputPdf);
	push (@{$self->{'garbage'}}, $self->{'pdf'});
	push (@{$self->{'pdfs'}}, $layputPdf);
	return 1;
}

sub composePdf{
	my ($self, $args) = @_;
	
	print STDERR "\033[34mComposing PDF " . $args->{'output'} . " \033[0m\n";
	prFile({'Name' => $args->{'output'},
	        'FitWindow'    => 1,
	        'CenterWindow' => 1,
	        'HideToolbar'  => 1,
	        'HideMenubar'  => 1,
	        'HideWindowUI' => 1,
	        'FitWindow'    => 1,
        });
	#prMbox ( 0,0,0,0 );
	# Set cprrect size
	prMbox(0, 0, $self->{'width'}, $self->{'height'});
	prCompress(1);

	foreach (@{$self->{'pdfs'}}){
		prImage({'file'  => $_,
			'adjust' => 1,
			});
		prPage();
	}
	prEnd;	
	foreach (@{$self->{'pdfs'}}){
		unlink $_ if -e $_;
	}
	return 1;
}

sub addText{
	my ($self, $args) = @_;

	print STDERR "   Add text \n";

	use Data::Dumper;
	warn Dumper $args;
	# Set correct font path, set fontsize

	if ($args->{'align'} eq 'Center'){
		$args->{'placeX'} += ($args->{'placeWidth'}/2);
	} elsif ($args->{'align'} eq 'Right'){
		$args->{'placeX'} += $args->{'placeWidth'};
	}

	print STDERR $self->{'template'}->Annotate(
				  font      => $args->{'ttf'},
				  #pen       => 'black',
                                  fill      => ($args->{'fontColor'} || '#000000'),
                                  pointsize => ($args->{'fontSize'}  || 0),
				  #stroke    => '#000000',
				  #strokewidth => 5,
				  #undercolor => '#000000',
                                  #gravity   => 'East',
				  #geometry  => '+' . $args->{'placeWidth'} . '+' . $args->{'placeHeight'},
                                  text      => ($args->{'text'} || ''),
				  align     =>  $args->{'align'},
				  #gravity   => 'East',
				  x => $args->{'placeX'},
				  y => $args->{'placeY'},
				);
#	print STDERR $self->{'template'}->Draw(
#				primitive=>'text',
#				  font      => $args->{'ttf'},
#                                  #pen       => 'black',
#                                 fill      => ($args->{'fontColor'} || '#000000'),
#				 'pointsize' => ($args->{'fontSize'}  || 0),
#				  stroke    => '#000000',
#				  'strokewidth' => 5,
#				  #decorate => 'UnderLine',
#				  #undercolor => '#000000',
#                                  #gravity   => 'East',
#				  #geometry  => '+' . $args->{'placeWidth'} . '+' . $args->{'placeHeight'},
#                                  text      => ($args->{'text'} || ''),
#				  #align     =>  $args->{'align'},
#				  #gravity   => 'East',
#				  x => 100 || $args->{'placeX'},
#				  y => 100 || $args->{'placeY'},
#				);
	#$self->{'template'}->Composite( 
		     #image       => $self->{'template'},
                     #compose    =>  'Atop',
                     #mask        => $self->{'template'},
       #              gravity     => 'East',
       #              quality     => 100,
                     #interpolate => 'bilinear',
       #              );
	return 1;
}

sub write{
	my ($self, $args) = @_;

	print STDERR "   Writing text \n";
	return 1;
}

sub cleanUp{
	my ($self, $args) = @_;

	foreach (@{$self->{'garbage'}}){
		undef $_;
	}
	return 1;
}

1;
