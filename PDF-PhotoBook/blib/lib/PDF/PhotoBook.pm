package PDF::PhotoBook;

use 5.010000;
use strict;
use warnings;
use Image::Magick;
use PDF::Reuse;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use PDF::PhotoBook ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
   my ($class, $args) = @_;
   my $self = {};

   bless($self, $class);
   
   return $self;
}

# Public methods
sub SetTempDir{
    my ($self, $dir) = @_;

    $self->{'tmpdir'} = $dir || '/tmp';
    return 1;
}

sub AddLayouts{
    my ($self, $layouts) = @_;

    $self->{'layouts'} = $layouts || die('Missing param layouts for AddLayouts');
    return 1;
}

sub Create{
    my ($self, $pdf) = @_;

    foreach (@{$self->{'layouts'}}){

        $self->SetSizes($_->{'width'}, $_->{'height'});
        $self->CreatePage;
        foreach (@{$_->{'placeholders'}}){
            if ($_->{'type'} eq 'image'){
                if (!$self->CheckImageFormat({'userImage' => $_->{'filepath'}})){
                    warn "Image in unknown format: " . $_->{'filepath'} . "\n";
                    next;
                }
                $self->ApplyMask({
                        'userImage'   => $_->{'filepath'},
                        'mask'        => $_->{'mask'},
                        'placeWidth'  => $_->{'width'},
                        'placeHeight' => $_->{'height'},
                        'placeX'      => $_->{'x'},
                        'placeY'      => $_->{'y'},
                        'imageWidth'  => $_->{'imageWidth'},
                        'imageHeight' => $_->{'imageHeight'},
                        'imageX'      => ($_->{'imageX'}   || 0),
                        'imageY'      => ($_->{'imageY'} || 0),
                        'flop'        => $_->{'flop'},
                        'degrees'     => $_->{'degrees'},
                        });
                $self->ApplyFrame({'frame'  => $_->{'frame'},
                        'placeWidth'  => $_->{'width'},
                        'placeHeight' => $_->{'height'},
                                      });
                # Additional params here!!!
                $self->Paint({
                        'placeX'      => $_->{'x'},
                        'placeY'      => $_->{'y'},
                        });
            } elsif ($_->{'type'} eq 'text'){
                if (!$_->{'text'} || $_->{'text'} eq ''){
                    warn "Missing param text\n";
                }
                if (!-e $_->{'ttf'}){
                    print STDERR "File not found TTF font: " . $_->{'ttf'} . "\n";
                    next;
                }
                $self->Write({
                            'placeWidth'  => $_->{'width'},
                            'placeHeight' => $_->{'height'},
                            'placeX'      => $_->{'x'},
                            'placeY'      => $_->{'y'},
                            'ttf'         => $_->{'ttf'},
                            'fontColor'   => $_->{'color'},
                            'align'       => $_->{'align'},
                            'text'        => $_->{'text'},
                            'fontSize'    => $_->{'size'},
                            });
            }
        }
        $self->{'tempdir'} ||= '/tmp';
        my $tmpPdf = $self->{'tempdir'} . time . ".pdf";
        $self->CreateLayoutPdf($tmpPdf);
        $self->CleanUp();
    }    
    $self->ComposePdf($pdf);
    return 1;
}

# Private methods
sub CreatePage{
   my ($self, $args) = @_;

   $self->{'template'} = Image::Magick->new();
   $self->{'template'}->Set('size' => $self->{'width'} . 'x' . $self->{'height'});
   $self->{'template'}->ReadImage( "xc: white");
   return 1;
}

sub SetSizes{
   my ($self, $width, $height) = @_;
   
   $self->{'width'}  = $width;
   $self->{'height'} = $height;
   return 1;
}

sub CheckImageFormat{
   my ($self, $args) = @_;
   
   $self->{'userImage'} = Image::Magick->new();
   my ($width, $height, $size, $format) = $self->{'userImage'}->Ping($args->{'userImage'});
   
   if (!$format){
      return 0;
   }
   $self->{'userImageType'} = $format;
   $self->{'imageWidth'}    = $width;
   $self->{'imageHeight'}   = $height;
   return 1;
}

sub ApplyMask{
   my ($self, $args) = @_;

   $self->{'userImage'}->ReadImage( $self->{'userImageType'} . ":" . $args->{'userImage'});
   $self->{'userImage'}->Set( alpha => 'set');
   
   # Zoom, Crop etc...
   # Rotate image
   if ($args->{'degrees'} && $args->{'degrees'} > 0){
      $self->{'userImage'}->Rotate(degrees => $args->{'degrees'}, background => 'none');
   }
   if ($args->{'imageWidth'} && $args->{'imageHeight'}){
       $self->{'userImage'}->Resize(geometry => $args->{'imageWidth'} . 'x' . $args->{'imageHeight'});
   }

   $args->{'imageX'} = $args->{'imageX'} * -1;
   $args->{'imageY'} = $args->{'imageY'} * -1;
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
   } 
   push (@{$self->{'garbage'}}, $self->{'userImage'});
   return 1;
}

sub ApplyFrame{
   my ($self, $args) = @_;
   
   if ($args->{'frame'}){
      $self->{'framed'} = Image::Magick->new();
      $self->{'framed'}->ReadImage( "png:" . $args->{'frame'});

      $self->{'framed'}->Resize(width => $args->{'placeWidth'}, height => $args->{'placeHeight'});
      $self->{'userImage'}->Composite( image => $self->{'framed'},
                        compose => 'over',
                        gravity => 'Center',
                        quality => 100,
                      );
      push (@{$self->{'garbage'}}, $self->{'framed'});
   } 
   return 1;
}


sub Paint{
   my ($self, $args) = @_;

   print STDERR $self->{'template'}->Composite(
               image => $self->{'userImage'},
               compose => 'Over',
               #rotate  => 20,
               gravity => 'NorthWest',
               geometry=> '+' . $args->{'placeX'} . '+' . $args->{'placeY'},
               #geometry=>'10x10',
               );
   return 1;
}

sub CreateLayoutPdf{
   my ($self, $layputPdf) = @_;

   $self->{'pdf'} = Image::Magick->new();
   # Set correct size
   $self->{'pdf'}->Set('size' => $self->{'width'} . 'x' . $self->{'height'});
   $self->{'pdf'}->ReadImage( "xc: white");

   $self->{'pdf'}->Composite( image => $self->{'template'},
                    compose => 'Over',
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

sub ComposePdf{
   my ($self, $pdf) = @_;
   
   prFile({'Name' => $pdf,
           'FitWindow'    => 1,
           'CenterWindow' => 1,
           'HideToolbar'  => 1,
           'HideMenubar'  => 1,
           'HideWindowUI' => 1,
           'FitWindow'    => 1,
        });
   # Set size
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

sub Write{
   my ($self, $args) = @_;

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
               x         => $args->{'placeX'},
               y         => $args->{'placeY'},
               antialias => 1,
            );
   return 1;
}

sub CleanUp{
   my ($self, $args) = @_;

   foreach (@{$self->{'garbage'}}){
      undef $_;
   }
   return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PDF::PhotoBook - Perl extension for building amazing photobooks ready to be printed out on any printable mashine.

=head1 SYNOPSIS

  use PDF::PhotoBook;
  my $book = new PDF::PhotoBook;
  $book->SetTempDir('/tmp'); # Optional. Default is /tmp
  my $layouts = [
         {'width'       => 500,
         'hieght'       => 800,
         'placeholders' => [
                     {
                     'type'        => 'image',          # Placeholder type image/text
                     'filepath'    => 'test.jpg',       # Image path
                     'width'       => 100,              # Placeholder width
                     'height'      => 300,              # Placeholder height
                     'x'           => 100,              # X cordinates
                     'y'           => 100,              # Y cordinates
                     },
                     {
                     'type'     => 'text',      # Placeholder type image/text
                     'width'    => 100,         # Placeholder width
                     'height'   => 300,         # Placeholder height
                     'x'        => 0,           # X cordinates
                     'y'        => 500,         # Y cordinates
                     'text'     => 'Test text', # Text content
                     'ttf'      => 'arial.ttf', # TTF font path
                     'color'    => '#000000',   # Font color
                     'size'     => '22',        # Font size
                     },
                  ],
         }, 
         {'width'       => 500,
         'hieght'       => 800,
         'placeholders' => [
                     {
                     'type'        => 'image',          # Placeholder type image/text
                     'filepath'    => 'test.jpg',       # Image path
                     'width'       => 100,              # Placeholder width
                     'height'      => 300,              # Placeholder height
                     'x'           => 100,              # X cordinates
                     'y'           => 100,              # Y cordinates
                     },
                ]
         }
         ];
  $book->AddLayouts($layouts);
  $book->Create($pdfpath);

=head1 DESCRIPTION

PDF::PhotoBook is an object oriented perl module wich allows you to create custom PDF files with images and text suitable for printing a real photobook.

=head2 METHODS
    
    PDF::PhotoBook::SetTempDir($path)
        Just sets the temporary directory which is used for holding the PDF pades before adding them to the complete output PDF
        These temporary pages are deleted after the job is done. Be careful to set the correct rights to this directory.
        If you did't set it the defaul directory is /tmp but it is recommended to set it manualy

    PDF::PhotoBook::AddLayouts($layouts)
        Just stores the whole configuration into the object

    PDF::PhotoBook::Create($pdfpath)
        Read the whole configuration and create the output pdf

=head2 CONFIGURATION PARAMETERS

    Configuration passed to AddLayouts is an anonymous array with anonymous hashes and should have the following format:
    [
         {'width'       => $pageWidth,  # Page width
         'hieght'       => $pageHeight, # Page height
         'placeholders' => [ # These are all placeholders in the page
                     { # Example image placeholder with full param set
                     'type'        => $type,        # Placeholder type image/text
                     'filepath'    => $imagePath,   # Image path
                     'width'       => $paceWidth,   # Placeholder width
                     'height'      => $placeHeight, # Placeholder height
                     'x'           => $x,           # X cordinates
                     'y'           => $y,           # Y cordinates
                     'mask'        => $mask,        # Optional. This is the path to the mask
                                                    # If we have frame we must apply transparency mask before adding it. 
                     'frame'       => $frame,       # Optional. If we have frame.
                     'imageWidth'  => $imageWidth,  # For resizing the image
                     'imageHeight' => $imageHeight, # For resizing the image 
                     'imageX'      => $imageX,      # Optional. This is used to crop the image if we want to
                     'imageY'      => $imageY,      # Optional. This is used to crop the image if we want to
                     'flop'        => $flop,        # Optional. If we want to flop the image true/false
                     'degrees'     => $degrees,     # Optional. If we need a rotation
                     },
                     { # Example text placeholder with full param set
                     'type'     => 'text',     # Placeholder type image/text
                     'width'    => $width,     # Placeholder width
                     'height'   => $height,    # Placeholder height
                     'x'        => $x,         # X cordinates
                     'y'        => $y,         # Y cordinates
                     'text'     => $text,      # Text content
                     'ttf'      => $fontpath,  # TTF font path
                     'color'    => $fontColor, # Font color
                     'size'     => $fontSize,  # Font size
                     'align'    => $align,     # Optional. Default is left. Text align in the placeholder - left/right/center
                     },
                  ],
         } 
    ]

=head1 SEE ALSO

Image::Magick
PDF::Reuse

http://it-bg.com

=head1 AUTHOR

sickboy, E<lt>sickboy@anarchy.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by ergon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
