package PhotoAlbums::PhotoAlbums::Controller::OrderProcessor;
use PhotoAlbums::PhotoAlbums::Model::OrderAlbumLayouts;
use PhotoAlbums::PhotoAlbums::Model::Orders;
use PhotoAlbums::PhotoAlbums::Utils::Image;
use base "PhotoAlbums::PFrame1_2::Controller::Default";
use strict;

sub new {
	my ($class, $args) = @_;
	my $self = $class->SUPER::new();

	bless($self, $class);
	return $self;
}

sub init{
	my ($self, $args) = @_;
	my $orders        = undef;
   
	$self->{'orders'} = new PhotoAlbums::PhotoAlbums::Model::Orders;
	while (1){
		$orders = $self->{'orders'}->fetchAll({'filter' => {'IsProcessed' => 'N', 'Status' => 'Approved'}});
		foreach (@{$orders}){
			$self->_processOrder($_->[0], $_->[1], {
								'coverWidth'  => $_->[3], 
								'coverHeight' => $_->[4],
								'width'       => $_->[5],
								'height'      => $_->[6],
								'dpi'         => $_->[7],
								});
		}
		print STDERR "Sleeping...\n";
		sleep (3);
	}
	return 1;
}

sub _processOrder{
	my ($self, $orderId, $userId, $args) = @_;
	my $orders           = new PhotoAlbums::PhotoAlbums::Model::Orders;
	my $orderLayouts     = new PhotoAlbums::PhotoAlbums::Model::OrderAlbumLayouts;
	my $painter          = new PhotoAlbums::PhotoAlbums::Utils::Image;
	my $orderData        = undef;
	my $layoutPdf        = undef;
	my $orderPdf         = undef;
	my $layoutWidth      = undef;
	my $layoutHeight     = undef;
	
	$orderData = $self->_prepareOrderData($orderLayouts->fetchAllByOrder({'filter' => {'OrderID' => $orderId}}));

	foreach (sort {$orderData->{$a}->{'pageNum'} <=> $orderData->{$b}->{'pageNum'}} keys %{$orderData}){
		print STDERR "\n\033[31mProcessing layout " . $_ . "...\033[0m\n";
		#$painter->createMain($self->{'config'}->{'PNG_TEMPLATES_PATH'} . $orderData->{$_}->{'template'});
		if ($orderData->{$_}->{'pageNum'} == 0){
			# We have cover here
			$layoutWidth  = $self->_mm2pixel($args->{'dpi'}, $args->{'coverWidth'});
			$layoutHeight = $self->_mm2pixel($args->{'dpi'}, $args->{'coverHeight'});
		} else {
			$layoutWidth  = $self->_mm2pixel($args->{'dpi'}, $args->{'width'});
			$layoutHeight = $self->_mm2pixel($args->{'dpi'}, $args->{'height'});
		}
		$painter->setSizes($layoutWidth, $layoutHeight);
		$painter->createMain({'width' => $layoutWidth, 'height' => $layoutHeight});
		foreach (@{$orderData->{$_}->{'placeholders'}}){
			print STDERR "\nProcessing placeholder...\n";
			if ($_->{'IID'} && $_->{'IID'} > 0 && $_->{'ImageName'} && -e ($self->{'config'}->{'USER_IMAGES_PATH'} . $userId . '/' . $_->{'ImageName'})){
				if (!$painter->checkImageFormat({'userImage' => ($self->{'config'}->{'USER_IMAGES_PATH'} . $userId . '/' . $_->{'ImageName'} || '')})){
					print STDERR "Image in unknown format: " . $self->{'config'}->{'USER_IMAGES_PATH'} . $userId . '/' . $_->{'ImageName'} . "\n";
					next;
				}
				$painter->applyMask({
						'userImage' => ($self->{'config'}->{'USER_IMAGES_PATH'} . $userId . '/' . $_->{'ImageName'} || ''),
						'mask'      => ($_->{'Mask'} ? $self->{'config'}->{'FRAMES_IMAGES_PATH'} . $_->{'Mask'} : ''),
						'placeWidth'  => $self->_mm2pixel($args->{'dpi'}, $_->{'LW'}),
						'placeHeight' => $self->_mm2pixel($args->{'dpi'}, $_->{'LH'}),
						'placeX'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LX'}),
						'placeY'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LY'}),
						'imageWidth'  => $self->_mm2pixel($args->{'dpi'}, $_->{'IW'}),
						'imageHeight' => $self->_mm2pixel($args->{'dpi'}, $_->{'IH'}),
						'imageX'      => $self->_mm2pixel($args->{'dpi'}, $_->{'IX'}),
						'imageY'      => $self->_mm2pixel($args->{'dpi'}, $_->{'IY'}),
						'flop'        => ($_->{'LIFL'} eq 'Y' ? 1 : undef),
						'degrees'     => $_->{'IR'},
					     	    });
				$painter->applyFrame({'frame'  => ($_->{'FrameImage'} ? $self->{'config'}->{'FRAMES_IMAGES_PATH'} . $_->{'FrameImage'} : undef),
						'placeWidth'  => $self->_mm2pixel($args->{'dpi'}, $_->{'LW'}),
						'placeHeight' => $self->_mm2pixel($args->{'dpi'}, $_->{'LH'}),
					      	     });
				# Additional params here!!!
				$painter->paint({
						'placeX'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LX'}),
						'placeY'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LY'}),
						});
			} elsif ($_->{'LTID'} && $_->{'LTID'} > 0){
				if ($_->{'Content'} && $_->{'Content'} ne ''){
					if (!$_->{'TTF'}){
						print STDERR "Missing param TTF file\n";
						next;
					}
					if (!-e $self->{'config'}->{'FONTS_PATH'} . $_->{'TTF'}){
						print STDERR "Unknown TTF font: " . $self->{'config'}->{'FONTS_PATH'} . $_->{'TTF'} . "\n";
						next;
					}
					$painter->addText({
							'placeWidth'  => $self->_mm2pixel($args->{'dpi'}, $_->{'LW'}),
							'placeHeight' => $self->_mm2pixel($args->{'dpi'}, $_->{'LH'}),
							'placeX'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LX'}),
							'placeY'      => $self->_mm2pixel($args->{'dpi'}, $_->{'LY'}),
							'ttf'         => $self->{'config'}->{'FONTS_PATH'} . $_->{'TTF'},
							'fontColor'   => $_->{'FontColor'},
							'align'       => $_->{'Align'},
							'text'        => $_->{'Content'},
							'fontSize'    => $_->{'FontSize'},
							});
					$painter->write();
				}
			}
		}
		$layoutPdf = $self->{'config'}->{'TEMP_DIR'} . sprintf($self->{'config'}->{'LAYOUT_PDF'}, $_) . '.' . $self->{'config'}->{'PDF_EXT'};
		$painter->createLayoutPdf($layoutPdf);
		$painter->cleanUp();
	}
	$orderPdf = sprintf($self->{'config'}->{'ALBUM_PDF'}, $orderId) . '.' . $self->{'config'}->{'PDF_EXT'};
	$painter->composePdf({'output' => $self->{'config'}->{'ORDER_ALBUMS_PATH'} . $orderPdf});
	$orders->update({'id' => $orderId, 'fields' => {'PdfAlbum' => $orderPdf, 
							'IsProcessed' => 'Y',
						}});
	return 1;
}

sub _mm2pixel{
	my ($self, $dpi, $mm) = @_;

	# 0.0393700787 mm per inch
	return int (($mm * 0.0393700787) * $dpi);
}

sub _prepareOrderData{
	my ($self, $data) = @_;
	my $orderData     = {};

	#foreach (sort {$a->{'PageNum'} <=> $b->{'PageNum'}} values %{$data}){
	foreach (sort { $a->{'PageNum'} <=> $b->{'PageNum'} || $a->{'ZIndex'} <=> $b->{'ZIndex'} } values %{$data}){
		#$orderData->{$_->{'LayoutID'}}->{'template'} = $_->{'Template'};
		$orderData->{$_->{'OrderAlbumLayoutID'}}->{'pageNum'} = $_->{'PageNum'} if !$orderData->{$_->{'OrderAlbumLayoutID'}}->{'pageNum'};
		push (@{$orderData->{$_->{'OrderAlbumLayoutID'}}->{'placeholders'}}, $_);
	}
	
	return $orderData;
}

1;
